# 🛠️ Instructions de Test : Debug "Mes Courses Chauffeur"

## 🎯 **OBJECTIF**
Diagnostiquer pourquoi la page "Mes Courses" du chauffeur n'affiche aucune course.

## 🚀 **Étapes de Test**

### **Étape 1 : Lancer l'App avec Debug**
```bash
cd /Users/bihangojustin/Desktop/DEVS/PROJECTS/bita-express-mobile
flutter run
```

### **Étape 2 : Se Connecter comme Chauffeur**
1. **Ouvrir l'application**
2. **Se connecter** avec un compte chauffeur existant
   - Ou créer un compte et le migrer vers chauffeur
3. **Vérifier** que l'utilisateur est bien de type "chauffeur"

### **Étape 3 : Accéder à "Mes Courses"**
1. **Naviguer** vers le menu principal
2. **Cliquer** sur "Mes Courses"
3. **Observer** les logs dans la console Flutter

### **Étape 4 : Analyser les Logs**

Les logs suivants vont apparaître dans la console :

```
=== CHARGEMENT COURSES CHAUFFEUR ===
✅ Token trouvé: Bearer eyJhbGciOiJIU...
👤 Données utilisateur:
  - ID: [ID_DU_CHAUFFEUR]
  - Username: [USERNAME]
  - Type: [TYPE_UTILISATEUR]
  - Statut: [STATUT]

=== APPEL API COURSES CHAUFFEUR ===
URL: [BASE_URL]/course/chauffeur/
Token: Bearer eyJhbGciOiJIU...
=== RÉPONSE API CHAUFFEUR ===
Status Code: [CODE_RÉPONSE]
Headers: {content-type: application/json}
Body: [DONNÉES_RÉPONSE]

📡 Réponse API:
  - Success: [true/false]
  - Message: [MESSAGE]
  - Data type: [TYPE_DONNÉES]
  - Data: [CONTENU_DONNÉES]

📊 Données courses:
  - Type: List<dynamic>
  - Nombre: [NOMBRE_COURSES]
  - Contenu: [DÉTAILS_COURSES]
```

## 🔍 **Interprétation des Résultats**

### **CAS 1 : Token Non Trouvé**
```
❌ Token non trouvé
```
**Solution** : Se reconnecter ou vérifier la session

### **CAS 2 : Type Utilisateur Incorrect**
```
👤 Données utilisateur:
  - Type: passager  ← PROBLÈME
```
**Solution** : Migrer le compte vers chauffeur

### **CAS 3 : Erreur API (Status ≠ 200)**
```
Status Code: 401  ← PROBLÈME
Body: {"detail": "Invalid token"}
```
**Solution** : Token expiré, se reconnecter

### **CAS 4 : Réponse Vide ou Malformée**
```
Body: []  ← PROBLÈME (liste vide)
ou
Body: {"error": "No courses found"}
```
**Solution** : Aucune course pour ce chauffeur

### **CAS 5 : Problème de Parsing**
```
💥 Erreur exception: type 'String' is not a subtype...
```
**Solution** : Structure de données inattendue

## 📋 **Scénario de Test Complet**

### **Test avec Données Réelles**
1. **Créer une course** (en tant que passager)
2. **Accepter la course** (en tant que chauffeur)  
3. **Vérifier "Mes Courses"** (course doit apparaître)

### **Commandes de Test**
```bash
# Lancer avec logs détaillés
flutter run --verbose

# Observer les logs en temps réel
flutter logs
```

## ✅ **Résultats Attendus**

### **Succès Normal**
```
=== CHARGEMENT COURSES CHAUFFEUR ===
✅ Token trouvé: Bearer eyJ...
👤 Données utilisateur:
  - ID: 123
  - Type: chauffeur  ← CORRECT
=== RÉPONSE API CHAUFFEUR ===
Status Code: 200  ← CORRECT
Body: [{"id": 456, "statut": "acceptee", ...}]  ← DONNÉES
✅ 1 courses chargées pour le chauffeur  ← SUCCÈS
```

### **Pas de Courses (Normal)**
```
📊 Données courses:
  - Nombre: 0  ← NORMAL si aucune course acceptée
✅ 0 courses chargées pour le chauffeur
```

## 🚨 **Actions Correctives**

### **Si le problème persiste :**
1. **Vérifier le serveur backend**
2. **Tester l'endpoint manuellement** 
3. **Vérifier la base de données**
4. **Créer des données de test**

Partagez les logs obtenus pour un diagnostic précis !
