-- Données de démonstration
INSERT INTO clients(code_client,nom,telephone,email,ville,type_client) VALUES
('CLI001','Société Alpha','+224620100001','alpha@example.com','Conakry','ENTREPRISE'),
('CLI002','Kindia Agro','+224620100002','kindia@example.com','Kindia','ENTREPRISE'),
('CLI003','Fouta Digital','+224620100003','fouta@example.com','Labé','ENTREPRISE'),
('CLI004','Kankan Innovation','+224620100004','kankan@example.com','Kankan','ENTREPRISE'),
('CLI005','Forest Tech','+224620100005','forest@example.com','Nzérékoré','ENTREPRISE')
ON CONFLICT (code_client) DO NOTHING;

INSERT INTO fournisseurs(code_fournisseur,nom,ville,pays) VALUES
('FOU001','Guinée Informatique Distribution','Conakry','Guinée'),
('FOU002','West Africa Technologies','Conakry','Guinée'),
('FOU003','Dakar Digital Supply','Dakar','Sénégal')
ON CONFLICT (code_fournisseur) DO NOTHING;

INSERT INTO produits(reference,nom,categorie,type_item,prix_achat_gnf,prix_vente_gnf,stock_minimum,stock_gere) VALUES
('PRD001','Laptop Dell Latitude 5440','Ordinateurs','PRODUIT',6500000,8500000,5,TRUE),
('PRD002','MacBook Pro','Ordinateurs','PRODUIT',18000000,22000000,2,TRUE),
('PRD003','Écran Dell 24 pouces','Périphériques','PRODUIT',1800000,2500000,5,TRUE),
('PRD004','Routeur MikroTik','Réseau','PRODUIT',1500000,2200000,5,TRUE),
('PRD005','Switch Cisco 24 Ports','Réseau','PRODUIT',3500000,4800000,3,TRUE),
('PRD006','SSD 1TB','Stockage','PRODUIT',600000,950000,10,TRUE),
('SRV001','Abonnement Mensuel','Services','SERVICE',0,2500000,0,FALSE),
('SRV002','Consultation IA','Intelligence Artificielle','SERVICE',0,6000000,0,FALSE),
('SRV003','Développement Web','Développement','SERVICE',0,15000000,0,FALSE),
('SRV004','Audit Sécurité','Cybersécurité','SERVICE',0,10000000,0,FALSE)
ON CONFLICT (reference) DO NOTHING;

INSERT INTO achats(numero_achat,id_fournisseur,date_achat,statut) VALUES
('ACH-2026-001',(SELECT id_fournisseur FROM fournisseurs WHERE code_fournisseur='FOU001'),'2026-08-20','REÇU'),
('ACH-2026-002',(SELECT id_fournisseur FROM fournisseurs WHERE code_fournisseur='FOU002'),'2026-08-25','REÇU')
ON CONFLICT (numero_achat) DO NOTHING;

INSERT INTO achat_lignes(id_achat,id_produit,quantite,prix_unitaire_gnf)
SELECT a.id_achat,p.id_produit,x.qte,x.prix FROM
(VALUES ('ACH-2026-001','PRD001',20::numeric,6500000::numeric),
        ('ACH-2026-001','PRD003',30::numeric,1800000::numeric),
        ('ACH-2026-002','PRD004',15::numeric,1500000::numeric),
        ('ACH-2026-002','PRD005',10::numeric,3500000::numeric)) x(achat,produit,qte,prix)
JOIN achats a ON a.numero_achat=x.achat JOIN produits p ON p.reference=x.produit
WHERE NOT EXISTS (SELECT 1 FROM achat_lignes al WHERE al.id_achat=a.id_achat AND al.id_produit=p.id_produit);

UPDATE achats a SET montant_total_gnf=x.total
FROM (SELECT id_achat,SUM(total_ligne_gnf) total FROM achat_lignes GROUP BY id_achat) x
WHERE a.id_achat=x.id_achat;

INSERT INTO ventes(numero_vente,id_client,date_vente,statut,mode_paiement) VALUES
('VTE-2026-001',(SELECT id_client FROM clients WHERE code_client='CLI001'),'2026-09-01 09:00','PAYÉ','VIREMENT'),
('VTE-2026-002',(SELECT id_client FROM clients WHERE code_client='CLI002'),'2026-09-02 11:00','PAYÉ','ORANGE_MONEY'),
('VTE-2026-003',(SELECT id_client FROM clients WHERE code_client='CLI003'),'2026-09-03 15:00','EN_ATTENTE',NULL),
('VTE-2026-004',(SELECT id_client FROM clients WHERE code_client='CLI004'),'2026-09-04 10:00','PAYÉ','VIREMENT')
ON CONFLICT (numero_vente) DO NOTHING;

INSERT INTO vente_lignes(id_vente,id_produit,quantite,prix_unitaire_gnf)
SELECT v.id_vente,p.id_produit,x.qte,x.prix FROM
(VALUES ('VTE-2026-001','PRD001',2::numeric,8500000::numeric),
        ('VTE-2026-001','SRV004',1::numeric,10000000::numeric),
        ('VTE-2026-002','PRD004',3::numeric,2200000::numeric),
        ('VTE-2026-003','SRV003',1::numeric,15000000::numeric),
        ('VTE-2026-004','SRV002',2::numeric,6000000::numeric)) x(vente,produit,qte,prix)
JOIN ventes v ON v.numero_vente=x.vente JOIN produits p ON p.reference=x.produit
WHERE NOT EXISTS (SELECT 1 FROM vente_lignes vl WHERE vl.id_vente=v.id_vente AND vl.id_produit=p.id_produit);

UPDATE ventes v SET montant_total_gnf=x.total
FROM (SELECT id_vente,SUM(total_ligne_gnf) total FROM vente_lignes GROUP BY id_vente) x
WHERE v.id_vente=x.id_vente;
UPDATE ventes SET montant_paye_gnf=montant_total_gnf WHERE statut='PAYÉ';

INSERT INTO mouvements_stock(id_produit,type_mouvement,quantite,id_achat,motif,date_mouvement)
SELECT al.id_produit,'ENTREE',al.quantite,al.id_achat,'Réception fournisseur',a.date_achat
FROM achat_lignes al JOIN achats a ON a.id_achat=al.id_achat
WHERE a.statut='REÇU' AND NOT EXISTS (
 SELECT 1 FROM mouvements_stock m WHERE m.id_achat=al.id_achat AND m.id_produit=al.id_produit AND m.type_mouvement='ENTREE'
);

INSERT INTO mouvements_stock(id_produit,type_mouvement,quantite,id_vente,motif,date_mouvement)
SELECT vl.id_produit,'SORTIE',vl.quantite,vl.id_vente,'Vente client',v.date_vente
FROM vente_lignes vl JOIN ventes v ON v.id_vente=vl.id_vente JOIN produits p ON p.id_produit=vl.id_produit
WHERE v.statut<>'ANNULÉ' AND p.stock_gere=TRUE AND NOT EXISTS (
 SELECT 1 FROM mouvements_stock m WHERE m.id_vente=vl.id_vente AND m.id_produit=vl.id_produit AND m.type_mouvement='SORTIE'
);
