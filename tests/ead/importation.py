from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.common.keys import Keys
from selenium.webdriver.support.ui import Select
from selenium.common.exceptions import NoSuchElementException
import unittest, time, re

class Importation(unittest.TestCase):
    def setUp(self):
        self.driver = webdriver.Firefox()
        self.addCleanup(self.driver.quit)
        self.driver.implicitly_wait(30)
        self.base_url = "https://scribe.ac-test.fr:4200/"
        self.verificationErrors = []
        self.accept_next_alert = True
    
    def test_importation(self):
        driver = self.driver
        driver.get(self.base_url + "/")
        driver.find_element_by_link_text("scribe").click()
        driver.find_element_by_id("username").clear()
        driver.find_element_by_id("username").send_keys("admin")
        driver.find_element_by_id("valider").click()
        driver.find_element_by_link_text("Outils").click()
        driver.find_element_by_css_selector("#menu_scribe_extraction > span").click()
        driver.find_element_by_link_text("Importation annuelle des bases").click()
        driver.find_element_by_link_text("Sconet").click()
        driver.find_element_by_link_text("Enseignants et personnels administratifs").click()
        driver.find_element_by_css_selector("#content > div > a").click()
        driver.find_element_by_css_selector("#content > div > a").click()
        driver.find_element_by_id("enseignant").clear()
        driver.find_element_by_id("enseignant").send_keys(u"/mnt/eole-ci-tests/dataset/données_scribe/sts_emp_0210050R_2009.xml")
        driver.find_element_by_css_selector("input[type=\"submit\"]").click()
        driver.find_element_by_css_selector("a.simple_link > h1").click()
        driver.find_element_by_css_selector("a.simple_link > h1").click()
        self.assertEqual(u"Importation des comptes en cours, veuillez conserver cette page. Cette opération peut être longue.", self.close_alert_and_get_its_text())
        self.assertEqual("Lecture des fichiers en cours, veuillez conserver cette page.", self.close_alert_and_get_its_text())
    
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
