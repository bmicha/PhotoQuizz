
# 📘 Cahier des charges – Application tvOS "Photo Quizz"

## 🎯 Objectif de l'application

Créer une application **tvOS** permettant de jouer à un **quizz photo entre amis**, basé sur les photos personnelles de l'utilisateur (issues de sa photothèque iCloud). Le but du jeu est d’**identifier l’endroit ou le contexte d’une photo** à partir d’un zoom progressif. L’utilisateur peut ensuite afficher la localisation et la date de la photo.

---

## 🧩 Fonctionnalités principales

### 1. **Accès aux photos utilisateur**
- Accès autorisé à la **photothèque iCloud** via `PHPhotoLibrary`.
- Sélection aléatoire de **10 photos** contenant des métadonnées de localisation.
- Optionnel : filtrer les photos sans coordonnées GPS.

### 2. **Affichage progressif (zoom/dézoom)**
- Démarrer chaque photo avec un **zoom important** sur un point aléatoire.
- Toutes les **3 secondes**, un **dézoom progressif** est appliqué (zoom-out animé).
- L'utilisateur peut **passer à la réponse** à tout moment via une touche de la télécommande.

### 3. **Révélation de la réponse**
- À la demande (touche "Réponse"), affichage :
  - de la **photo complète**.
  - de la **position GPS sur une carte** (via `MapKit`).
  - de la **date de prise de vue** (issue des métadonnées EXIF).

### 4. **Session de 10 photos**
- Une session de jeu contient **10 photos aléatoires**.
- Navigation de l’une à l’autre avec validation de la réponse.

---

## 🎮 Interface Utilisateur (tvOS)

### Écran d’accueil
- Titre du jeu.
- Bouton “Démarrer une partie”.

### Écran de jeu (1 photo)
- Affichage de la photo en cours :
  - Vue `UIImageView` avec animation de zoom-out.
- Bouton “Afficher la réponse” (`UIButton` ou détection touche Siri Remote).
- Affichage d’un compteur `x / 10`.

### Écran de réponse
- Photo non zoomée.
- Carte centrée sur la localisation.
- Date formatée (ex. : "12 août 2022 à 16h45").

### Écran final
- Récapitulatif (facultatif) : par exemple, montrer toutes les localisations sur une carte.

---

## 🗺️ Technologies & Frameworks

| Fonction | Framework | Détail |
|---------|-----------|--------|
| Accès aux photos | `Photos` (PHPhotoLibrary) | Pour parcourir les photos et métadonnées |
| Animation zoom | `Core Animation` ou `UIView.animate` | Zoom progressif (transform) |
| Affichage carte | `MapKit` | Affichage des coordonnées GPS |
| Interface TV | `UIKit for tvOS` | Interface avec télécommande Siri |
| Gestion de session | `Swift` | Logique de sélection, score, navigation |

---

## 🔐 Autorisations requises

Dans le fichier `Info.plist` :
```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>Nous avons besoin d'accéder à vos photos pour jouer au quizz !</string>
```

---

## 📦 Architecture technique

- `PhotoManager` : responsable de la sélection aléatoire de 10 photos avec métadonnées.
- `GameManager` : gestion de la partie (compteur, état, transitions).
- `ZoomPhotoViewController` : zoom progressif.
- `RevealViewController` : carte et métadonnées.
- `MapHelper` : centrer la carte sur les coordonnées GPS.

---

## 🧪 Test & simulation

- Prévoir un mode démo avec photos embarquées (si accès iCloud impossible).
- Ajouter des logs pour la lecture des métadonnées EXIF.

---

## 📝 Prochaines étapes

1. **Créer le projet Xcode tvOS**
2. **Configurer l’accès à la photothèque**
3. **Lire les photos avec métadonnées GPS**
4. **Créer le composant d’affichage zoom progressif**
5. **Afficher la carte et la date**
6. **Gérer la navigation entre les 10 photos**
