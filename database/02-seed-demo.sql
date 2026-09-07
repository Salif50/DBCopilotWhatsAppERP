INSERT INTO public.clients(code_client,nom,ville,type_client) VALUES
('CLI001','Société Alpha','Conakry','ENTREPRISE'),
('CLI002','Kindia Agro','Kindia','ENTREPRISE'),
('CLI003','Fouta Digital','Labé','ENTREPRISE'),
('CLI004','Kankan Innovation','Kankan','ENTREPRISE'),
('CLI005','Forest Tech','Nzérékoré','ENTREPRISE')
ON CONFLICT (code_client) DO NOTHING;

INSERT INTO public.fournisseurs(code_fournisseur,nom,ville,pays) VALUES
('FOU001','Guinée Informatique Distribution','Conakry','Guinée'),
('FOU002','West Africa Technologies','Conakry','Guinée'),
('FOU003','Dakar Digital Supply','Dakar','Sénégal')
ON CONFLICT (code_fournisseur) DO NOTHING;

INSERT INTO public.produits(reference,nom,categorie,type_item,prix_achat_gnf,prix_vente_gnf,stock_minimum,stock_gere) VALUES
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
