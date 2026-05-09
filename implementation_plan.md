# 📋 Plan d'Implémentation — Contrôle Pharma

Application mobile Flutter de **contrôle/audit de pharmacie** permettant de comparer le stock théorique vs réel, détecter les écarts et calculer les pertes/bénéfices.

> ⚠️ Ce n'est **PAS** une application de vente ou de caisse. C'est un outil d'audit financier.

---

## Phase 1 : Setup du projet Flutter
- Créer le projet Flutter
- Structurer les dossiers : `models/`, `screens/`, `widgets/`, `services/`, `providers/`
- Installer les dépendances : `provider`, `sqflite`, `path_provider`, `intl`
- Configurer le thème de l'application (couleurs, typographie)

---

## Phase 2 : Modèle de données
- Créer la classe `Medicament` avec tous les champs
- Implémenter les getters calculés :
  - `quantiteRestante = quantiteInitiale - quantiteVendue`
  - `pvTotal = prixVente * quantiteVendue`
  - `benefice = (prixVente - prixUnitaire) * quantiteVendue`
  - `ecart = stockReel - quantiteRestante`
- Créer la classe `Controle` (session de contrôle avec date et liste de médicaments)

---

## Phase 3 : Interface utilisateur (UI)

### Écrans à créer :
1. **DashboardScreen** — Écran principal avec bouton "Nouveau contrôle" et historique
2. **MedicamentFormScreen** — Formulaire d'ajout de médicament (nom, qté initiale, PU, PV)
3. **VenteScreen** — Saisie des quantités vendues par médicament
4. **ControleScreen** — Saisie du stock réel et affichage des écarts
5. **TableauControleScreen** — Tableau récapitulatif type Excel avec totaux

---

## Phase 4 : Logique métier
- Provider `ControleProvider` pour gérer l'état
- Calculs automatiques en temps réel
- Validation des entrées (pas de valeurs négatives, champs obligatoires)
- Gestion des erreurs avec messages utilisateur

---

## Phase 5 : Tableau de contrôle
- Tableau scrollable horizontal avec colonnes :
  | Nom | Q.I | P.U | P.V | Q.Vendue | PV Total | Q.Restante | Stock Réel | Écart | Bénéfice |
- Ligne de totaux en bas (total PV, total bénéfice)
- Code couleur : 🔴 perte / 🟢 bénéfice

---

## Phase 6 : Amélioration UX
- Indicateurs visuels rouge/vert pour les écarts
- Alertes automatiques si écart détecté
- Interface rapide et claire (inspiration Excel)
- Animations subtiles pour les transitions

---

## Phase 7 : Stockage des données
- Implémentation SQLite via `sqflite`
- Tables : `controles`, `medicaments`
- CRUD complet
- Historique des contrôles consultable

---

## 🗂 Structure des fichiers

```
lib/
├── main.dart
├── models/
│   ├── medicament.dart
│   └── controle.dart
├── providers/
│   └── controle_provider.dart
├── screens/
│   ├── dashboard_screen.dart
│   ├── medicament_form_screen.dart
│   ├── vente_screen.dart
│   ├── controle_screen.dart
│   └── tableau_controle_screen.dart
├── widgets/
│   ├── medicament_card.dart
│   ├── ecart_indicator.dart
│   └── summary_row.dart
├── services/
│   └── database_service.dart
└── utils/
    ├── constants.dart
    └── formatters.dart
```

---

## 📦 Dépendances

| Package | Usage |
|---------|-------|
| `provider` | Gestion d'état |
| `sqflite` | Base de données locale |
| `path_provider` | Chemins système |
| `intl` | Formatage nombres/dates |

---

## 🎨 Palette de couleurs

- **Primaire** : Bleu pharma `#1565C0`
- **Bénéfice/OK** : Vert `#2E7D32`
- **Perte/Écart** : Rouge `#C62828`
- **Background** : Blanc/Gris clair
- **Texte** : Gris foncé `#212121`
