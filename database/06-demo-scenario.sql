-- =====================================================================
--  DB Copilot — 06 : SCÉNARIO DE DÉMO propre (à exécuter APRÈS 01,02,05)
--  Aligné sur le schéma réel (colonnes total_ligne_gnf GENERATED : jamais insérées).
--  Résultat garanti et crédible pour le 12/09/2026 :
--   • Tout le stock repasse positif et sain (fini les valeurs négatives).
--   • 3 produits phares en RUPTURE nette : Laptop Dell, SSD 1TB, Écran Dell
--     (stock bas mais positif, sous le minimum, ~2 jours avant rupture).
--   • CAUSE en base : une commande fournisseur passée le 04/09 et NON livrée.
-- =====================================================================
BEGIN;

-- 1) Rebalancer TOUT le stock géré vers un niveau sain (corrige les négatifs)
DO $$
DECLARE p RECORD; cur NUMERIC; cible NUMERIC; diff NUMERIC;
BEGIN
  FOR p IN SELECT id_produit, stock_minimum FROM public.produits WHERE stock_gere=TRUE LOOP
    SELECT stock_actuel INTO cur FROM public.v_stock_produits WHERE id_produit=p.id_produit;
    cible := GREATEST(COALESCE(p.stock_minimum,0)*4, 40);
    diff := cible - COALESCE(cur,0);
    IF diff <> 0 THEN
      INSERT INTO public.mouvements_stock(id_produit,type_mouvement,quantite,motif,date_mouvement,commentaire)
      VALUES (p.id_produit,
              CASE WHEN diff>0 THEN 'AJUSTEMENT_POSITIF' ELSE 'AJUSTEMENT_NEGATIF' END,
              ABS(diff), 'Correction stock ouverture', TIMESTAMP '2026-06-30 08:00:00',
              'Remise à niveau démo');
    END IF;
  END LOOP;
END $$;

-- 2) Historique de consommation récent des 3 produits phares (pour un taux réaliste)
INSERT INTO public.mouvements_stock(id_produit,type_mouvement,quantite,motif,date_mouvement,commentaire)
SELECT p.id_produit,'SORTIE',2,'Vente client',
       (TIMESTAMP '2026-08-31 10:00:00' + (g-1)*INTERVAL '1 day'),
       'Consommation démo'
FROM (VALUES ('PRD001'),('PRD006'),('PRD003')) r(reference)
JOIN public.produits p ON p.reference=r.reference
CROSS JOIN generate_series(1,12) g;

-- 3) Fixer le stock final des 3 phares : bas, positif, sous le minimum
DO $$
DECLARE r RECORD; cur NUMERIC; cible NUMERIC; diff NUMERIC;
BEGIN
  FOR r IN SELECT * FROM (VALUES ('PRD001',4::numeric),('PRD006',6::numeric),('PRD003',3::numeric)) v(reference,cible) LOOP
    PERFORM 1;
    SELECT s.stock_actuel INTO cur FROM public.v_stock_produits s
      JOIN public.produits p ON p.id_produit=s.id_produit WHERE p.reference=r.reference;
    diff := r.cible - COALESCE(cur,0);
    IF diff <> 0 THEN
      INSERT INTO public.mouvements_stock(id_produit,type_mouvement,quantite,motif,date_mouvement,commentaire)
      SELECT p.id_produit,
             CASE WHEN diff>0 THEN 'AJUSTEMENT_POSITIF' ELSE 'AJUSTEMENT_NEGATIF' END,
             ABS(diff),'Inventaire',TIMESTAMP '2026-09-11 18:30:00','Rupture démo'
      FROM public.produits p WHERE p.reference=r.reference;
    END IF;
  END LOOP;
END $$;

-- 4) CAUSE : commande de réappro des 3 phares passée le 04/09 et NON livrée (statut COMMANDE)
INSERT INTO public.achats(numero_achat,id_fournisseur,date_achat,statut,montant_total_gnf,commentaire)
SELECT 'DEMO-LATE-1209', id_fournisseur, TIMESTAMP '2026-09-04 09:00:00','COMMANDE',0,
       'Réapprovisionnement Laptop Dell / SSD / Écran — NON LIVRÉ (retard fournisseur)'
FROM public.fournisseurs
ORDER BY id_fournisseur LIMIT 1
ON CONFLICT (numero_achat) DO NOTHING;

INSERT INTO public.achat_lignes(id_achat,id_produit,quantite,prix_unitaire_gnf)
SELECT a.id_achat,p.id_produit,x.qte,p.prix_achat_gnf
FROM (VALUES ('PRD001',30::numeric),('PRD006',40::numeric),('PRD003',25::numeric)) x(reference,qte)
JOIN public.achats a ON a.numero_achat='DEMO-LATE-1209'
JOIN public.produits p ON p.reference=x.reference
WHERE NOT EXISTS (SELECT 1 FROM public.achat_lignes al WHERE al.id_achat=a.id_achat AND al.id_produit=p.id_produit);

UPDATE public.achats a SET montant_total_gnf=x.total
FROM (SELECT id_achat,SUM(total_ligne_gnf) total FROM public.achat_lignes GROUP BY id_achat) x
WHERE a.id_achat=x.id_achat AND a.numero_achat='DEMO-LATE-1209';

COMMIT;
