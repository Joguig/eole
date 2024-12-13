# -*- coding: utf-8 -*-
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.common.keys import Keys
from selenium.webdriver.support.ui import Select
from selenium.common.exceptions import NoSuchElementException
from selenium.common.exceptions import NoAlertPresentException
import unittest, time, re

class LoginProf(unittest.TestCase):
    def setUp(self):
        self.driver = webdriver.Firefox()
        self.driver.implicitly_wait(30)
        self.base_url = "https://bogdanov.eole.lan/"
        self.verificationErrors = []
        self.accept_next_alert = True
    
    def test_login_prof(self):
        driver = self.driver
        driver.get(self.base_url + "${baseUrl}/${urlEOP}/index")
        driver.find_element_by_id("username").clear()
        driver.find_element_by_id("username").send_keys("${prof_login}")
        driver.find_element_by_id("password").clear()
        driver.find_element_by_id("password").send_keys("${prof_mdp}")
        driver.find_element_by_id("valider").click()
        # ERROR: Caught exception [ERROR: Unsupported command [selectWindow | null | ]]
        self.assertEqual("EOP - Accueil", driver.title)
        self.assertEqual("prof1", driver.find_element_by_id("loginInfo").text)
        self.assertEqual("Logout", driver.find_element_by_id("logout").text)
        try: self.assertEqual("Distribuer", driver.find_element_by_id("linkDistribuer").text)
        except AssertionError as e: self.verificationErrors.append(str(e))
        self.assertEqual("Ramasser", driver.find_element_by_id("linkRamasser").text)
        self.assertEqual("Rendre", driver.find_element_by_id("linkRendre").text)
        self.assertEqual("Historique", driver.find_element_by_id("linkHistorique").text)
    
    def is_element_present(self, how, what):
        try: self.driver.find_element(by=how, value=what)
        except NoSuchElementException, e: return False
        return True
    
    def is_alert_present(self):
        try: self.driver.switch_to_alert()
        except NoAlertPresentException, e: return False
        return True
    
    def close_alert_and_get_its_text(self):
        try:
            alert = self.driver.switch_to_alert()
            alert_text = alert.text
            if self.accept_next_alert:
                alert.accept()
            else:
                alert.dismiss()
            return alert_text
        finally: self.accept_next_alert = True
    
    def tearDown(self):
        self.driver.quit()
        self.assertEqual([], self.verificationErrors)

if __name__ == "__main__":
    unittest.main()
