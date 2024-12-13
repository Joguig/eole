import unittest
import suiteFilter

def suite()
    suite = unittest.TestSuite()
    suite.addTest(unittest.makeSuite(store_baseurl))
    suite.addTest(unittest.makeSuite(login_prof))
    suite.addTest(unittest.makeSuite(distribuer_ko_champs_vides))
    suite.addTest(unittest.makeSuite(distribuer))
    suite.addTest(unittest.makeSuite(distribuer_ko_ref_incorrecte))
    suite.addTest(unittest.makeSuite(logout_prof))
    suite.addTest(unittest.makeSuite(verifier_mail_distribution))
    suite.addTest(unittest.makeSuite(verifier_fichiers_eleve))
    suite.addTest(unittest.makeSuite(login_prof))
    suite.addTest(unittest.makeSuite(ramasser_liste))
    suite.addTest(unittest.makeSuite(logout_prof))
    suite.addTest(unittest.makeSuite(verifier_fichiers_prof))
    suite.addTest(unittest.makeSuite(login_prof))
    suite.addTest(unittest.makeSuite(rendre_liste))
    suite.addTest(unittest.makeSuite(logout_prof))
    suite.addTest(unittest.makeSuite(verifier_fichiers_eleve_rendu))
    suite.addTest(unittest.makeSuite(login_prof))
    suite.addTest(unittest.makeSuite(distribuer_2))
    suite.addTest(unittest.makeSuite(ramasser_gerer))
    suite.addTest(unittest.makeSuite(rendre_gerer))
    suite.addTest(unittest.makeSuite(logout_prof))
    suite.addTest(unittest.makeSuite(verifier_mail_rendu))
    return suite

if __name__ == "__main__":
    result = unittest.TextTestRunner(verbosity=2).run(suite())
    sys.exit(not result.wasSuccessful())
