from pymongo import MongoClient
from bson.objectid import ObjectId

client = MongoClient('mongodb://localhost:27017')
db = client['eoleaaf']
posts = db['user']


print db.user.count()
#for user in
#print list(db.user.find({'ENTEleveParents': ObjectId('59648036b92f3b7c2d22b000')}))
#print list(db.user.find({'_id': ObjectId('59648036b92f3b7c2d22b000')}))

# example de query
#person_id = db.user.find_one({'ENTPersonLogin': 'mohammed.tahiribenkassou01'})['_id']
#print list(db.user.find({'ENTEleveParents': person_id}))

print db.user.find_one({'UserType': 'eleve'})
#eleve = db.user.find_one({'UserType': 'eleve', 'uid': u'AGI14502' })
#print eleve
#
#etab_classe = eleve['ENTEleveClasses']
#print etab_classe['etablissement']
#print etab_classe['name']
etablissement = db.etablissement.find_one()
print etablissement
#matieres = db.subject.find()
#print matieres
#print db.user.find_one({'UserType': 'enseignant', 'ENTAuxEnsClassesMatieres': {u'etablissement': ObjectId('59647e47b92f3b7c2d1f710c'), u'class': u'3G1', u'subject': u'006900'}})
#print db.user.find({'UserType': 'enseignant', 'ENTAuxEnsClasses': eleve['ENTEleveClasses']}).count()
#enseignants = db.user.find({'UserType': 'enseignant'}) #, 'ENTPersonFonctions'['etablissement']: ObjectId(etab_classe['etablissement'])})
