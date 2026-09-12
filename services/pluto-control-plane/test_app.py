import os

os.environ.setdefault("PLUTO_CONTROL_TOKEN", "test-token")

from fastapi.testclient import TestClient

from app import app


client = TestClient(app)
HEADERS = {"X-PLUTO-Token": "test-token"}


def validate(sql: str):
    return client.post("/sql/validate", headers=HEADERS, json={"sql": sql}).json()


def test_allows_read_only_business_query():
    result = validate("SELECT nom, stock_actuel FROM public.v_stock_produits LIMIT 10")
    assert result["valid"] is True
    assert result["ast_root"] == "Select"


def test_allows_declared_business_join():
    result = validate(
        "SELECT c.nom, SUM(v.montant_paye_gnf) "
        "FROM clients c JOIN ventes v ON c.id_client = v.id_client GROUP BY c.nom"
    )
    assert result["valid"] is True


def test_blocks_write():
    assert validate("DELETE FROM ventes")["valid"] is False


def test_blocks_unlisted_table():
    assert validate("SELECT * FROM pg_catalog.pg_user")["valid"] is False


def test_blocks_union_and_subquery():
    assert validate("SELECT nom FROM clients UNION SELECT nom FROM fournisseurs")["valid"] is False
    assert validate("SELECT * FROM (SELECT * FROM ventes) AS x")["valid"] is False


def test_blocks_system_function_and_select_into():
    assert validate("SELECT pg_read_file('/etc/passwd') FROM ventes")["valid"] is False
    assert validate("SELECT * INTO sauvegarde FROM ventes")["valid"] is False


def test_blocks_cross_join_and_undeclared_relationship():
    assert validate("SELECT * FROM clients c CROSS JOIN ventes v")["valid"] is False
    assert validate(
        "SELECT * FROM clients c JOIN produits p ON c.id_client = p.id_produit"
    )["valid"] is False


def test_requires_token():
    response = client.post("/sql/validate", json={"sql": "SELECT * FROM ventes"})
    assert response.status_code == 401
