-- DB Copilot WhatsApp ERP
-- Seed enrichi pour la démo du 12 septembre 2026
-- Idempotent autant que possible, déterministe, sans random().

BEGIN;

-- 1) 96 clients supplémentaires
INSERT INTO public.clients (
  code_client, nom, telephone, email, ville, adresse, type_client, actif
)
SELECT
  'HCLI' || LPAD(gs::text, 3, '0'),
  CASE WHEN gs % 10 = 0 THEN 'Administration Régionale ' || gs
       WHEN gs % 7 = 0 THEN 'ONG Développement ' || gs
       ELSE 'Entreprise Démo ' || gs END,
  '+22462' || LPAD((1000000 + gs)::text, 7, '0'),
  'client' || gs || '@demo.local',
  CASE
    WHEN gs % 10 IN (0,1,2,3) THEN 'Conakry'
    WHEN gs % 10 = 4 THEN 'Kindia'
    WHEN gs % 10 = 5 THEN 'Labé'
    WHEN gs % 10 = 6 THEN 'Kankan'
    WHEN gs % 10 = 7 THEN 'Nzérékoré'
    WHEN gs % 10 = 8 THEN 'Boké'
    ELSE CASE WHEN gs % 2 = 0 THEN 'Mamou' ELSE 'Faranah' END
  END,
  'Adresse démo ' || gs,
  CASE WHEN gs % 10 = 0 THEN 'ADMINISTRATION'
       WHEN gs % 7 = 0 THEN 'ONG'
       ELSE 'ENTREPRISE' END,
  TRUE
FROM generate_series(1,96) gs
ON CONFLICT (code_client) DO NOTHING;

-- 2) 20 fournisseurs
INSERT INTO public.fournisseurs (
  code_fournisseur, nom, telephone, email, ville, pays, contact_principal, actif
)
SELECT
  'HFOU' || LPAD(gs::text, 2, '0'),
  CASE
    WHEN gs=1 THEN 'Global Supplies Guinea'
    WHEN gs=2 THEN 'West Africa Digital Distribution'
    WHEN gs=3 THEN 'Conakry Network Import'
    WHEN gs=4 THEN 'Dakar Professional Systems'
    ELSE 'Fournisseur Démo ' || gs
  END,
  '+2246213' || LPAD(gs::text,4,'0'),
  'supplier' || gs || '@demo.local',
  CASE WHEN gs<=10 THEN 'Conakry'
       WHEN gs<=14 THEN 'Dakar'
       WHEN gs<=17 THEN 'Abidjan'
       ELSE 'Dubai' END,
  CASE WHEN gs<=10 THEN 'Guinée'
       WHEN gs<=14 THEN 'Sénégal'
       WHEN gs<=17 THEN 'Côte d''Ivoire'
       ELSE 'Émirats Arabes Unis' END,
  'Contact Fournisseur ' || gs,
  TRUE
FROM generate_series(1,20) gs
ON CONFLICT (code_fournisseur) DO NOTHING;

-- 3) 52 produits
INSERT INTO public.produits (
  reference, nom, description, categorie, type_item, unite,
  prix_achat_gnf, prix_vente_gnf, stock_minimum, stock_gere, actif
)
SELECT
  'HPRD' || LPAD(gs::text,3,'0'),
  CASE
    WHEN gs BETWEEN 1 AND 8 THEN 'Laptop Business ' || gs
    WHEN gs BETWEEN 9 AND 16 THEN 'Équipement Réseau ' || gs
    WHEN gs BETWEEN 17 AND 24 THEN 'Périphérique Pro ' || gs
    WHEN gs BETWEEN 25 AND 32 THEN 'Stockage SSD ' || gs
    WHEN gs BETWEEN 33 AND 40 THEN 'Équipement Sécurité ' || gs
    WHEN gs BETWEEN 41 AND 48 THEN 'Énergie & Onduleur ' || gs
    ELSE 'Matériel IT ' || gs
  END,
  'Produit de démonstration hackathon ' || gs,
  CASE
    WHEN gs BETWEEN 1 AND 8 THEN 'Ordinateurs'
    WHEN gs BETWEEN 9 AND 16 THEN 'Réseau'
    WHEN gs BETWEEN 17 AND 24 THEN 'Périphériques'
    WHEN gs BETWEEN 25 AND 32 THEN 'Stockage'
    WHEN gs BETWEEN 33 AND 40 THEN 'Sécurité'
    WHEN gs BETWEEN 41 AND 48 THEN 'Énergie'
    ELSE 'Infrastructure'
  END,
  'PRODUIT','UNITE',
  400000 + (gs*275000),
  (400000 + (gs*275000)) +
    CASE WHEN gs%9=0 THEN 350000
         WHEN gs%7=0 THEN 4500000
         WHEN gs%5=0 THEN 2200000
         ELSE 1200000 + (gs%4)*450000 END,
  CASE WHEN gs%6=0 THEN 12 WHEN gs%5=0 THEN 8 ELSE 5 END,
  TRUE, TRUE
FROM generate_series(1,52) gs
ON CONFLICT (reference) DO NOTHING;

-- 4) Services
INSERT INTO public.produits (
  reference, nom, description, categorie, type_item, unite,
  prix_achat_gnf, prix_vente_gnf, stock_minimum, stock_gere, actif
) VALUES
('HSRV001','Conseil IA Avancé','Mission de conseil IA','Intelligence Artificielle','SERVICE','SERVICE',0,12000000,0,FALSE,TRUE),
('HSRV002','Automatisation n8n','Automatisation de processus métier','Automatisation','SERVICE','SERVICE',0,8500000,0,FALSE,TRUE),
('HSRV003','Audit Cybersécurité Pro','Audit sécurité approfondi','Cybersécurité','SERVICE','SERVICE',0,15000000,0,FALSE,TRUE),
('HSRV004','Développement ERP','Développement application ERP','Développement','SERVICE','SERVICE',0,28000000,0,FALSE,TRUE),
('HSRV005','Développement Mobile','Application mobile métier','Développement','SERVICE','SERVICE',0,22000000,0,FALSE,TRUE),
('HSRV006','Installation Infrastructure','Installation réseau/serveur','Infrastructure','SERVICE','SERVICE',0,9500000,0,FALSE,TRUE),
('HSRV007','Formation IA Entreprise','Formation IA pour équipes','Formation','SERVICE','SERVICE',0,6500000,0,FALSE,TRUE),
('HSRV008','Support Premium','Support technique premium','Services','SERVICE','SERVICE',0,4000000,0,FALSE,TRUE)
ON CONFLICT (reference) DO NOTHING;

-- 5) 320 achats déterministes
INSERT INTO public.achats (
  numero_achat,id_fournisseur,date_achat,statut,montant_total_gnf,commentaire
)
SELECT
  'HACH-2026-' || LPAD(gs::text,4,'0'),
  f.id_fournisseur,
  TIMESTAMP '2026-01-03 08:30:00'
    + ((gs*19)%248)*INTERVAL '1 day'
    + ((gs*37)%9)*INTERVAL '1 hour',
  CASE WHEN gs%31=0 THEN 'ANNULÉ'
       WHEN gs%17=0 THEN 'PARTIEL'
       WHEN gs%13=0 THEN 'COMMANDE'
       ELSE 'REÇU' END,
  0,
  'Achat de démonstration hackathon'
FROM generate_series(1,320) gs
JOIN public.fournisseurs f
  ON f.code_fournisseur =
     CASE
       WHEN gs%10 IN (0,1,2,3) THEN 'HFOU01'
       WHEN gs%10=4 THEN 'HFOU02'
       WHEN gs%10=5 THEN 'HFOU03'
       ELSE 'HFOU' || LPAD((((gs*7)%17)+4)::text,2,'0')
     END
ON CONFLICT (numero_achat) DO NOTHING;

INSERT INTO public.achat_lignes (
  id_achat,id_produit,quantite,prix_unitaire_gnf
)
SELECT
  a.id_achat,
  p.id_produit,
  4 + ((a.id_achat + line_no*3)%18),
  ROUND((p.prix_achat_gnf*(0.96 + ((a.id_achat+line_no)%5)*0.01))::numeric,2)
FROM public.achats a
CROSS JOIN generate_series(1,4) line_no
JOIN public.produits p
  ON p.reference='HPRD' || LPAD((((a.id_achat*7 + line_no*11)%52)+1)::text,3,'0')
WHERE a.numero_achat LIKE 'HACH-2026-%'
  AND line_no <= 2 + (a.id_achat%3)
  AND NOT EXISTS (
    SELECT 1 FROM public.achat_lignes al
    WHERE al.id_achat=a.id_achat AND al.id_produit=p.id_produit
  );

UPDATE public.achats a
SET montant_total_gnf=x.total
FROM (
  SELECT id_achat,SUM(total_ligne_gnf) total
  FROM public.achat_lignes
  GROUP BY id_achat
) x
WHERE a.id_achat=x.id_achat
  AND a.numero_achat LIKE 'HACH-2026-%';

-- 6) 1200 ventes
INSERT INTO public.ventes (
  numero_vente,id_client,date_vente,statut,mode_paiement,
  montant_total_gnf,montant_paye_gnf,commentaire
)
SELECT
  'HVTE-2026-' || LPAD(gs::text,5,'0'),
  c.id_client,
  TIMESTAMP '2026-01-01 08:00:00'
    + ((gs*29)%254)*INTERVAL '1 day'
    + ((gs*17)%10)*INTERVAL '1 hour'
    + ((gs*13)%60)*INTERVAL '1 minute',
  CASE WHEN gs%29=0 THEN 'ANNULÉ'
       WHEN gs%11=0 THEN 'EN_ATTENTE'
       WHEN gs%19=0 THEN 'PARTIEL'
       ELSE 'PAYÉ' END,
  CASE WHEN gs%5=0 THEN 'VIREMENT'
       WHEN gs%5=1 THEN 'ORANGE_MONEY'
       WHEN gs%5=2 THEN 'MTN_MONEY'
       WHEN gs%5=3 THEN 'ESPECES'
       ELSE 'CHEQUE' END,
  0,0,'Vente de démonstration hackathon'
FROM generate_series(1,1200) gs
JOIN public.clients c
  ON c.code_client='HCLI' || LPAD((((gs*13)%96)+1)::text,3,'0')
ON CONFLICT (numero_vente) DO NOTHING;

INSERT INTO public.vente_lignes (
  id_vente,id_produit,quantite,prix_unitaire_gnf,remise_gnf
)
SELECT
  v.id_vente,
  p.id_produit,
  CASE WHEN p.type_item='SERVICE' THEN 1
       ELSE 1 + ((v.id_vente+line_no)%5) END,
  p.prix_vente_gnf,
  CASE WHEN v.id_vente%23=0 THEN ROUND((p.prix_vente_gnf*0.05)::numeric,2)
       WHEN v.id_vente%41=0 THEN ROUND((p.prix_vente_gnf*0.10)::numeric,2)
       ELSE 0 END
FROM public.ventes v
CROSS JOIN generate_series(1,4) line_no
JOIN public.produits p
  ON p.reference =
     CASE
       WHEN v.date_vente >= TIMESTAMP '2026-08-01'
            AND line_no=1
            AND v.id_vente%4=0
       THEN CASE WHEN v.id_vente%2=0 THEN 'HSRV001' ELSE 'HSRV002' END
       WHEN line_no=1 AND v.id_vente%17=0 THEN 'HSRV004'
       WHEN line_no=1 AND v.id_vente%19=0 THEN 'HSRV003'
       ELSE 'HPRD' || LPAD((((v.id_vente*11 + line_no*7)%52)+1)::text,3,'0')
     END
WHERE v.numero_vente LIKE 'HVTE-2026-%'
  AND line_no <= 1 + (v.id_vente%4)
  AND NOT EXISTS (
    SELECT 1 FROM public.vente_lignes vl
    WHERE vl.id_vente=v.id_vente AND vl.id_produit=p.id_produit
  );

UPDATE public.ventes v
SET montant_total_gnf=x.total
FROM (
  SELECT id_vente,SUM(total_ligne_gnf) total
  FROM public.vente_lignes
  GROUP BY id_vente
) x
WHERE v.id_vente=x.id_vente
  AND v.numero_vente LIKE 'HVTE-2026-%';

UPDATE public.ventes
SET montant_paye_gnf =
  CASE WHEN statut='PAYÉ' THEN montant_total_gnf
       WHEN statut='PARTIEL' THEN ROUND(montant_total_gnf*0.55,2)
       ELSE 0 END
WHERE numero_vente LIKE 'HVTE-2026-%';

-- 7) Opérations spéciales du 12/09/2026
INSERT INTO public.ventes (
  numero_vente,id_client,date_vente,statut,mode_paiement,
  montant_total_gnf,montant_paye_gnf,commentaire
)
SELECT * FROM (
  VALUES
  ('HDEMO-1209-001',(SELECT id_client FROM public.clients WHERE code_client='HCLI001'),TIMESTAMP '2026-09-12 09:05:00','PAYÉ','VIREMENT',0::numeric,0::numeric,'Hackathon day'),
  ('HDEMO-1209-002',(SELECT id_client FROM public.clients WHERE code_client='HCLI045'),TIMESTAMP '2026-09-12 09:42:00','PAYÉ','ORANGE_MONEY',0::numeric,0::numeric,'Hackathon day'),
  ('HDEMO-1209-003',(SELECT id_client FROM public.clients WHERE code_client='HCLI012'),TIMESTAMP '2026-09-12 10:51:00','PAYÉ','VIREMENT',0::numeric,0::numeric,'Hackathon day'),
  ('HDEMO-1209-004',(SELECT id_client FROM public.clients WHERE code_client='HCLI034'),TIMESTAMP '2026-09-12 11:27:00','PAYÉ','MTN_MONEY',0::numeric,0::numeric,'Hackathon day'),
  ('HDEMO-1209-005',(SELECT id_client FROM public.clients WHERE code_client='HCLI052'),TIMESTAMP '2026-09-12 12:14:00','EN_ATTENTE','VIREMENT',0::numeric,0::numeric,'Hackathon day'),
  ('HDEMO-1209-006',(SELECT id_client FROM public.clients WHERE code_client='HCLI067'),TIMESTAMP '2026-09-12 13:36:00','PAYÉ','VIREMENT',0::numeric,0::numeric,'Hackathon day'),
  ('HDEMO-1209-007',(SELECT id_client FROM public.clients WHERE code_client='HCLI020'),TIMESTAMP '2026-09-12 14:47:00','PAYÉ','VIREMENT',0::numeric,0::numeric,'Hackathon day'),
  ('HDEMO-1209-008',(SELECT id_client FROM public.clients WHERE code_client='HCLI073'),TIMESTAMP '2026-09-12 15:22:00','ANNULÉ','ORANGE_MONEY',0::numeric,0::numeric,'Hackathon day'),
  ('HDEMO-1209-009',(SELECT id_client FROM public.clients WHERE code_client='HCLI089'),TIMESTAMP '2026-09-12 16:08:00','PAYÉ','VIREMENT',0::numeric,0::numeric,'Hackathon day'),
  ('HDEMO-1209-010',(SELECT id_client FROM public.clients WHERE code_client='HCLI006'),TIMESTAMP '2026-09-12 16:32:00','PARTIEL','CHEQUE',0::numeric,0::numeric,'Hackathon day')
) x(numero_vente,id_client,date_vente,statut,mode_paiement,montant_total_gnf,montant_paye_gnf,commentaire)
ON CONFLICT (numero_vente) DO NOTHING;

INSERT INTO public.vente_lignes (
  id_vente,id_produit,quantite,prix_unitaire_gnf,remise_gnf
)
SELECT v.id_vente,p.id_produit,x.quantite,p.prix_vente_gnf,0
FROM (
  VALUES
  ('HDEMO-1209-001','HSRV004',1::numeric),
  ('HDEMO-1209-001','HPRD001',1::numeric),
  ('HDEMO-1209-002','HSRV007',1::numeric),
  ('HDEMO-1209-003','HPRD010',4::numeric),
  ('HDEMO-1209-003','HPRD012',3::numeric),
  ('HDEMO-1209-004','HSRV001',1::numeric),
  ('HDEMO-1209-004','HPRD006',1::numeric),
  ('HDEMO-1209-005','HSRV003',1::numeric),
  ('HDEMO-1209-006','HSRV004',1::numeric),
  ('HDEMO-1209-007','HPRD021',5::numeric),
  ('HDEMO-1209-007','HSRV002',1::numeric),
  ('HDEMO-1209-008','HSRV005',1::numeric),
  ('HDEMO-1209-009','HPRD033',3::numeric),
  ('HDEMO-1209-009','HSRV006',1::numeric),
  ('HDEMO-1209-010','HPRD041',2::numeric)
) x(numero_vente,reference,quantite)
JOIN public.ventes v ON v.numero_vente=x.numero_vente
JOIN public.produits p ON p.reference=x.reference
WHERE NOT EXISTS (
  SELECT 1 FROM public.vente_lignes vl
  WHERE vl.id_vente=v.id_vente AND vl.id_produit=p.id_produit
);

UPDATE public.ventes v
SET montant_total_gnf=x.total
FROM (
  SELECT id_vente,SUM(total_ligne_gnf) total
  FROM public.vente_lignes
  GROUP BY id_vente
) x
WHERE v.id_vente=x.id_vente
  AND v.numero_vente LIKE 'HDEMO-1209-%';

UPDATE public.ventes
SET montant_paye_gnf=
  CASE WHEN statut='PAYÉ' THEN montant_total_gnf
       WHEN statut='PARTIEL' THEN ROUND(montant_total_gnf*0.50,2)
       ELSE 0 END
WHERE numero_vente LIKE 'HDEMO-1209-%';

-- achat important du 12 septembre
INSERT INTO public.achats (
  numero_achat,id_fournisseur,date_achat,statut,montant_total_gnf,commentaire
)
SELECT 'HACH-1209-001',id_fournisseur,TIMESTAMP '2026-09-12 10:18:00',
       'REÇU',0,'Réapprovisionnement hackathon day'
FROM public.fournisseurs
WHERE code_fournisseur='HFOU01'
ON CONFLICT (numero_achat) DO NOTHING;

INSERT INTO public.achat_lignes(id_achat,id_produit,quantite,prix_unitaire_gnf)
SELECT a.id_achat,p.id_produit,x.qte,p.prix_achat_gnf
FROM (
  VALUES ('HPRD006',30::numeric),('HPRD012',20::numeric),('HPRD021',18::numeric)
) x(reference,qte)
JOIN public.achats a ON a.numero_achat='HACH-1209-001'
JOIN public.produits p ON p.reference=x.reference
WHERE NOT EXISTS (
  SELECT 1 FROM public.achat_lignes al
  WHERE al.id_achat=a.id_achat AND al.id_produit=p.id_produit
);

UPDATE public.achats a
SET montant_total_gnf=x.total
FROM (
  SELECT id_achat,SUM(total_ligne_gnf) total
  FROM public.achat_lignes
  GROUP BY id_achat
) x
WHERE a.id_achat=x.id_achat
  AND a.numero_achat='HACH-1209-001';

-- 8) Mouvements de stock
INSERT INTO public.mouvements_stock (
  id_produit,type_mouvement,quantite,id_achat,motif,date_mouvement
)
SELECT al.id_produit,'ENTREE',al.quantite,al.id_achat,'Réception fournisseur',a.date_achat
FROM public.achat_lignes al
JOIN public.achats a ON a.id_achat=al.id_achat
JOIN public.produits p ON p.id_produit=al.id_produit
WHERE a.statut='REÇU'
  AND p.stock_gere=TRUE
  AND NOT EXISTS (
    SELECT 1 FROM public.mouvements_stock m
    WHERE m.id_achat=al.id_achat
      AND m.id_produit=al.id_produit
      AND m.type_mouvement='ENTREE'
  );

INSERT INTO public.mouvements_stock (
  id_produit,type_mouvement,quantite,id_vente,motif,date_mouvement
)
SELECT vl.id_produit,'SORTIE',vl.quantite,vl.id_vente,'Vente client',v.date_vente
FROM public.vente_lignes vl
JOIN public.ventes v ON v.id_vente=vl.id_vente
JOIN public.produits p ON p.id_produit=vl.id_produit
WHERE v.statut<>'ANNULÉ'
  AND p.stock_gere=TRUE
  AND NOT EXISTS (
    SELECT 1 FROM public.mouvements_stock m
    WHERE m.id_vente=vl.id_vente
      AND m.id_produit=vl.id_produit
      AND m.type_mouvement='SORTIE'
  );

-- stocks critiques volontaires
INSERT INTO public.mouvements_stock (
  id_produit,type_mouvement,quantite,motif,date_mouvement,commentaire
)
SELECT p.id_produit,'AJUSTEMENT_NEGATIF',x.qte,'Ajustement inventaire',
       TIMESTAMP '2026-09-11 18:00:00',
       'Stocks critiques créés pour la démo'
FROM (
  VALUES
  ('HPRD005',18::numeric),
  ('HPRD014',14::numeric),
  ('HPRD027',22::numeric),
  ('HPRD036',16::numeric),
  ('HPRD048',20::numeric)
) x(reference,qte)
JOIN public.produits p ON p.reference=x.reference
WHERE NOT EXISTS (
  SELECT 1 FROM public.mouvements_stock m
  WHERE m.id_produit=p.id_produit
    AND m.type_mouvement='AJUSTEMENT_NEGATIF'
    AND m.date_mouvement=TIMESTAMP '2026-09-11 18:00:00'
);

COMMIT;

-- Résumé volumes
SELECT 'clients' entite, COUNT(*) total FROM public.clients
UNION ALL SELECT 'fournisseurs',COUNT(*) FROM public.fournisseurs
UNION ALL SELECT 'produits',COUNT(*) FROM public.produits
UNION ALL SELECT 'ventes',COUNT(*) FROM public.ventes
UNION ALL SELECT 'vente_lignes',COUNT(*) FROM public.vente_lignes
UNION ALL SELECT 'achats',COUNT(*) FROM public.achats
UNION ALL SELECT 'achat_lignes',COUNT(*) FROM public.achat_lignes
UNION ALL SELECT 'mouvements_stock',COUNT(*) FROM public.mouvements_stock;
