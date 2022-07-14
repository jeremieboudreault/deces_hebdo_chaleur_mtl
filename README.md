Décès hebdomadaires au Québec en fonction de la chaleur observée 🌡
================================================================================

...

Données
--------------------------------------------------------------------------------

J'ai téléchargé les données de décès hebdomadaires de `2010` à `2022` à partir du site web de l'[Institut de la Statistique du Québec](https://statistique.quebec.ca/fr/document/nombre-hebdomadaire-de-deces-au-quebec) (ISQ). 

__Figure 1 : Décès hebdomadaires par âge__

![](plots/fig_1_deces_par_age.jpg)

__Figure 2 : Décès hebdomadaires par région__

![](plots/fig_2_deces_par_region.jpg)

__Figure 3 : Décès hebdomadaires par sexe__

![](plots/fig_3_deces_par_sexe.jpg)

J'ai ensuite téléchargé les données des stations météorologiques d'Environnement et Changement climatique Canada (ECCC) situées à Montréal à l'aide du package `weathercan` au pas de temps quotidien pour la température minimale, maximale et minimale. À des fins de simplication, les données de toutes les stations ont été aggrégées spatialement.

__Figure 4 : Températures quotidiennes à Montréal__

![](plots/fig_3_montreal_temp.jpg)

Finalement, les données ont été ramenées ont pas de temps hebdomadaire en prenant la moyenne des températures quotidienne minimales, moyennes et maximales, en plus du minimum des températures quotidiennes minimales et du maximum des températures quotidiennes maximales. Ces données ont été fusionné avec les données de décès de l'ISQ pour la région de Montréal et Laval, sans distinction avec les groupes d'âge ou les sexes.

Résultats
--------------------------------------------------------------------------------



Conclusion
--------------------------------------------------------------------------------



Pistes futures
--------------------------------------------------------------------------------




___Enjoy !___ ✌🏻
