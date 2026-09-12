import hashlib
import json
import os
import re
from typing import Any

from fastapi import Depends, FastAPI, Header, HTTPException
from pydantic import BaseModel, Field
from redis import Redis
from sqlglot import exp, parse
from sqlglot.errors import ParseError


app = FastAPI(title="PLUTO Control Plane", version="1.0.0")

ALLOWED_TABLES = {
    "clients", "fournisseurs", "produits", "ventes", "vente_lignes",
    "achats", "achat_lignes", "mouvements_stock", "v_stock_produits",
}
ALLOWED_RELATIONSHIPS = {
    frozenset({("ventes", "id_client"), ("clients", "id_client")}),
    frozenset({("vente_lignes", "id_vente"), ("ventes", "id_vente")}),
    frozenset({("vente_lignes", "id_produit"), ("produits", "id_produit")}),
    frozenset({("achats", "id_fournisseur"), ("fournisseurs", "id_fournisseur")}),
    frozenset({("achat_lignes", "id_achat"), ("achats", "id_achat")}),
    frozenset({("achat_lignes", "id_produit"), ("produits", "id_produit")}),
    frozenset({("mouvements_stock", "id_produit"), ("produits", "id_produit")}),
    frozenset({("mouvements_stock", "id_vente"), ("ventes", "id_vente")}),
    frozenset({("mouvements_stock", "id_achat"), ("achats", "id_achat")}),
    frozenset({("v_stock_produits", "id_produit"), ("produits", "id_produit")}),
}
FORBIDDEN_AST_NODES = {
    "Alter", "Analyze", "Command", "Commit", "Copy", "Create", "Delete",
    "Drop", "Execute", "Grant", "Insert", "LoadData", "Lock", "Merge",
    "Into", "Pragma", "Rollback", "Set", "Transaction", "TruncateTable", "Update",
    "Use", "Vacuum",
}
FORBIDDEN_FUNCTIONS = {
    "current_setting", "dblink", "lo_export", "lo_import", "pg_ls_dir",
    "pg_read_binary_file", "pg_read_file", "pg_sleep", "set_config",
}


def redis_client() -> Redis:
    return Redis.from_url(
        os.getenv("REDIS_URL", "redis://redis:6379/0"),
        decode_responses=True,
        socket_connect_timeout=1.5,
        socket_timeout=1.5,
    )


def authorize(x_pluto_token: str | None = Header(default=None)) -> None:
    expected = os.getenv("PLUTO_CONTROL_TOKEN", "").strip()
    if not expected or x_pluto_token != expected:
        raise HTTPException(status_code=401, detail="invalid control token")


def memory_key(chat_id: str) -> str:
    digest = hashlib.sha256(chat_id.strip().encode("utf-8")).hexdigest()
    return f"pluto:conversation:{digest}"


class SqlRequest(BaseModel):
    sql: str = Field(min_length=1, max_length=20_000)


class MemoryGetRequest(BaseModel):
    chat_id: str = Field(min_length=3, max_length=160)


class MemorySetRequest(BaseModel):
    chat_id: str = Field(min_length=3, max_length=160)
    question: str = Field(min_length=1, max_length=2_000)
    analytical_question: str = Field(default="", max_length=2_000)
    answer_summary: str = Field(default="", max_length=2_000)
    generated_sql: str = Field(default="", max_length=20_000)
    had_chart: bool = False


@app.get("/health")
def health() -> dict[str, Any]:
    try:
        redis_ok = bool(redis_client().ping())
    except Exception:
        redis_ok = False
    return {"status": "ok" if redis_ok else "degraded", "redis": redis_ok}


@app.post("/sql/validate", dependencies=[Depends(authorize)])
def validate_sql(request: SqlRequest) -> dict[str, Any]:
    sql = request.sql.strip()
    if ";" in sql or re.search(r"--|/\*|\*/", sql):
        return {"valid": False, "error": "Instructions multiples ou commentaires interdits", "stage": "lexical"}
    try:
        statements = parse(sql, read="postgres")
    except ParseError as exc:
        return {"valid": False, "error": str(exc)[:500], "stage": "parse"}
    if len(statements) != 1:
        return {"valid": False, "error": "Une seule instruction SQL est autorisée", "stage": "ast"}

    tree = statements[0]
    if not isinstance(tree, exp.Select):
        return {"valid": False, "error": f"Racine AST interdite: {type(tree).__name__}", "stage": "ast"}

    node_names = {type(item).__name__ for item in tree.walk()}
    forbidden = sorted(node_names.intersection(FORBIDDEN_AST_NODES))
    if forbidden:
        return {"valid": False, "error": f"Nœuds AST interdits: {', '.join(forbidden)}", "stage": "ast"}
    if any(isinstance(item, (exp.Subquery, exp.With, exp.Union, exp.Intersect, exp.Except)) for item in tree.walk()):
        return {"valid": False, "error": "Sous-requêtes, CTE et opérations ensemblistes interdites", "stage": "ast"}

    tables = []
    aliases = {}
    for table in tree.find_all(exp.Table):
        name = table.name.lower()
        schema = (table.db or "public").lower()
        if schema != "public" or name not in ALLOWED_TABLES:
            return {"valid": False, "error": f"Table interdite: {schema}.{name}", "stage": "ast"}
        tables.append(name)
        aliases[(table.alias_or_name or name).lower()] = name
    if not tables:
        return {"valid": False, "error": "Aucune table métier autorisée", "stage": "ast"}

    for join in tree.find_all(exp.Join):
        if not join.args.get("on"):
            return {"valid": False, "error": "JOIN sans condition ON interdite", "stage": "relations"}
        allowed_equality_found = False
        for equality in join.args["on"].find_all(exp.EQ):
            left, right = equality.left, equality.right
            if not isinstance(left, exp.Column) or not isinstance(right, exp.Column):
                continue
            left_table = aliases.get((left.table or "").lower())
            right_table = aliases.get((right.table or "").lower())
            if not left_table or not right_table:
                continue
            relationship = frozenset({
                (left_table, left.name.lower()),
                (right_table, right.name.lower()),
            })
            if relationship in ALLOWED_RELATIONSHIPS:
                allowed_equality_found = True
                break
        if not allowed_equality_found:
            return {"valid": False, "error": "Relation JOIN non autorisée", "stage": "relations"}

    functions = set()
    for function in tree.find_all(exp.Func):
        # Les fonctions inconnues sont représentées par Anonymous dans SQLGlot :
        # leur vrai nom se trouve dans .name, pas dans sql_name().
        name = str(getattr(function, "name", "") or function.sql_name()).lower()
        functions.add(name)
        if name in FORBIDDEN_FUNCTIONS or name.startswith("pg_"):
            return {"valid": False, "error": f"Fonction interdite: {name}", "stage": "ast"}

    normalized = tree.sql(dialect="postgres", pretty=False)
    return {
        "valid": True,
        "normalized_sql": normalized,
        "tables": sorted(set(tables)),
        "functions": sorted(functions),
        "ast_root": type(tree).__name__,
        "fingerprint": hashlib.sha256(normalized.encode("utf-8")).hexdigest()[:16],
    }


@app.post("/memory/get", dependencies=[Depends(authorize)])
def get_memory(request: MemoryGetRequest) -> dict[str, Any]:
    try:
        raw = redis_client().get(memory_key(request.chat_id))
        if not raw:
            return {"available": True, "found": False, "context": None}
        return {"available": True, "found": True, "context": json.loads(raw)}
    except Exception as exc:
        return {"available": False, "found": False, "context": None, "error": str(exc)[:300]}


@app.post("/memory/set", dependencies=[Depends(authorize)])
def set_memory(request: MemorySetRequest) -> dict[str, Any]:
    ttl = max(300, min(int(os.getenv("PLUTO_MEMORY_TTL_SECONDS", "86400")), 604800))
    payload = request.model_dump()
    payload.pop("chat_id", None)
    payload["stored_fields"] = ["question", "analytical_question", "answer_summary", "generated_sql", "had_chart"]
    try:
        redis_client().setex(memory_key(request.chat_id), ttl, json.dumps(payload, ensure_ascii=False))
        return {"stored": True, "ttl_seconds": ttl}
    except Exception as exc:
        return {"stored": False, "error": str(exc)[:300]}
