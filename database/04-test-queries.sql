-- Tests fonctionnels
SELECT COUNT(*) AS clients FROM clients;
SELECT COUNT(*) AS produits FROM produits;
SELECT COUNT(*) AS ventes FROM ventes;

SELECT c.ville, COALESCE(SUM(v.montant_total_gnf),0) AS ca_gnf
FROM ventes v JOIN clients c ON c.id_client=v.id_client
WHERE v.statut='PAYÉ'
GROUP BY c.ville ORDER BY ca_gnf DESC;

SELECT p.nom, SUM(vl.quantite) quantite_vendue, SUM(vl.total_ligne_gnf) ca_gnf
FROM vente_lignes vl JOIN produits p ON p.id_produit=vl.id_produit
JOIN ventes v ON v.id_vente=vl.id_vente
WHERE v.statut='PAYÉ'
GROUP BY p.id_produit,p.nom ORDER BY ca_gnf DESC;

SELECT * FROM v_stock_produits ORDER BY stock_actuel;
SELECT * FROM v_stock_produits WHERE stock_actuel <= stock_minimum ORDER BY stock_actuel;

SELECT f.nom, SUM(a.montant_total_gnf) total_achats_gnf
FROM achats a JOIN fournisseurs f ON f.id_fournisseur=a.id_fournisseur
WHERE a.statut='REÇU'
GROUP BY f.id_fournisseur,f.nom ORDER BY total_achats_gnf DESC;
