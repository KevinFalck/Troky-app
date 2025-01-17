# Troky 🎲🌍

**Troky** est une application mobile compatible IOS et Android destinée aux parents qui souhaitent échanger des jouets pour enfants. Elle vise à économiser de l'argent tout en adoptant une démarche écologique en donnant une seconde vie aux jouets inutilisés.

SITE WEB: Https://Troky.fr
---

## 🌟 Fonctionnalités principales

- **Géolocalisation automatique** : Localisation des utilisateurs pour afficher les jouets disponibles dans un rayon de 15 km.
- **Recherche avancée** : Barre de recherche permettant de trouver des jouets dans une ville spécifique.
- **Favoris** : Ajout et gestion des jouets préférés.
- **Profil utilisateur** : Bio, avis et statistiques des parents.
- **Publication de jouets** : Téléversement d'images (jusqu'à 4 par annonce) et description.
- **Page jouet dédiée** : Détails du jouet, avis sur le parent propriétaire, et options de contact.
- **Footer navigation** : Accès rapide aux sections clés (favoris, publication, chat, profil).

---

## 🛠️ Stack technique

### **Frontend**
- Framework : [Flutter](https://flutter.dev/)
- Plateformes : Android et iOS

### **Backend**
- Langage : [Node.js](https://nodejs.org/)
- Framework : Express.js

### **Base de données**
- Type : [MongoDB](https://www.mongodb.com/) (NoSQL)

### **Hébergement**
- **Serveur cloud** : [AWS EC2](https://aws.amazon.com/ec2/)
- **Stockage d'images** : [AWS S3 Bucket](https://aws.amazon.com/s3/)

---

## 🚀 Installation et utilisation

### Prérequis
- **Node.js** (v16+ recommandé)
- **Flutter SDK** (v3.0+)
- **MongoDB** (ou accès à une instance MongoDB Atlas)
- **AWS CLI** (configuré avec des droits pour S3 et EC2)

### Étapes

1. **Cloner le dépôt** :
   ```bash
   git clone https://github.com/KevinFalck/troky-app.git
   cd troky-app
   ```

2. **Backend** :
   - Aller dans le répertoire `backend` :
     ```bash
     cd backend
     ```
   - Installer les dépendances :
     ```bash
     npm install
     ```
   - Créer un fichier `.env` avec vos variables :
     ```env
     PORT=3000
     MONGO_URI=Votre_URL_MongoDB
     AWS_ACCESS_KEY_ID=Votre_Clé_AWS
     AWS_SECRET_ACCESS_KEY=Votre_Secret_AWS
     AWS_S3_BUCKET=Nom_de_votre_bucket
     ```
   - Lancer le serveur :
     ```bash
     npm start
     ```

3. **Frontend** :
   - Aller dans le répertoire `frontend` :
     ```bash
     cd frontend
     ```
   - Installer les dépendances Flutter :
     ```bash
     flutter pub get
     ```
   - Lancer l'application :
     ```bash
     flutter run
     ```

4. **Hébergement** :
   - Déployer le backend sur une instance EC2.
   - Configurer S3 pour l'hébergement des images.

---

## 🗺️ Roadmap

### Version actuelle (prototype)
- Mise en ligne des jouets avec géolocalisation automatique et recherche manuelle.
- Gestion des favoris.
- Système de profil utilisateur.

### Évolutions futures
- Chat en temps réel entre parents.
- Système de "match" pour indiquer un intérêt mutuel.
- Notifications pour les favoris et nouveaux jouets disponibles.

---

## 📄 Licence

Ce projet est sous licence MIT. Voir le fichier [LICENSE](./LICENSE) pour plus de détails.

---

## 📧 Contact

Pour toute question ou suggestion, contactez-moi à contact@kevinfalck.tech

---

## 🌍 Contributions

Les contributions sont les bienvenues ! N'hésitez pas à ouvrir une [issue](https://github.com/kevinfalck/troky-app/issues) ou soumettre une [pull request](https://github.com/kevinfalck/troky-app/pulls).
