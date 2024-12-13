# -*- coding: utf-8 -*-
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.common.keys import Keys
from selenium.webdriver.support.ui import Select
from selenium.common.exceptions import NoSuchElementException
from selenium.common.exceptions import NoAlertPresentException
from eolecitests import EoleCiTests

class DistribuerOk(EoleCiTests):
    def test_distribuer_ok(self):
        driver = self.driver
        driver.find_element_by_link_text("EOP").click()
        driver.find_element_by_css_selector("b.caret").click()
        driver.find_element_by_link_text("Distribuer").click()
        driver.find_element_by_id("nomdev").clear()
        driver.find_element_by_id("nomdev").send_keys("Devoir 1 test selenium")
        Select(driver.find_element_by_id("groupe")).select_by_visible_text("c31")
        driver.find_element_by_id("eleve_only-0").click()
        driver.find_element_by_css_selector("div.plupload.html5 input:nth(0)").clear()
        driver.find_element_by_css_selector("div.plupload.html5 input:nth(0)").send_keys("${basePath}/docupload.txt")
        driver.find_element_by_css_selector("div.plupload.html5 input:nth(1)").clear()
        driver.find_element_by_css_selector("div.plupload.html5 input:nth(1)").send_keys("${basePath}/annexeupload.txt")
        driver.find_element_by_id("rep_dest-0").click()
        driver.find_element_by_id("dist_envoi_mail").click()
        driver.find_element_by_id("dist_sujet_mail").clear()
        driver.find_element_by_id("dist_sujet_mail").send_keys("Sujet du mail de test devoir 1")
        driver.find_element_by_id("dist_corps_mail").clear()
        driver.find_element_by_id("dist_corps_mail").send_keys("Contenu du mail de test devoir 1")
        driver.find_element_by_id("btnSubmitDistribuer").click()
        self.assertEqual("Devoir 1 test selenium", driver.find_element_by_id("recap-ref").text)
        self.assertEqual(u"Distribuer immédiatement", driver.find_element_by_id("recap-inperso").text)
        self.assertEqual(u"Uniquement aux élèves", driver.find_element_by_id("recap-eleveonly").text)
        self.assertEqual("c31", driver.find_element_by_id("recap-groupes").text)
        self.assertEqual("docupload.txt", driver.find_element_by_id("recap-dev").text)
        self.assertEqual("annexeupload.txt", driver.find_element_by_id("recap-data").text)
        driver.find_element_by_id("recap-confirm").click()
        driver.find_element_by_id("link-historique").click()
        self.assertEqual("devoir_1_test_selenium-c31", driver.find_element_by_xpath("//table[@id='tableauhistorique']/tbody/tr/td[1]").text)
        self.assertEqual("c31", driver.find_element_by_xpath("//table[@id='tableauhistorique']/tbody/tr/td[2]").text)
        self.assertEqual("oui", driver.find_element_by_xpath("//table[@id='tableauhistorique']/tbody/tr/td[3]").text)
        self.assertEqual(u"Distribué", driver.find_element_by_xpath("//table[@id='tableauhistorique']/tbody/tr/td[4]").text)
        self.assertEqual("Ramasser", driver.find_element_by_xpath("//table[@id='tableauhistorique']/tbody/tr/td[5]").text)
        self.assertEqual(u"Uniquement aux élèves", driver.find_element_by_id("recap-eleveonly").text)
        self.assertEqual(u"Uniquement aux élèves", driver.find_element_by_id("recap-eleveonly").text)
        self.assertEqual(u"Uniquement aux élèves", driver.find_element_by_id("recap-eleveonly").text)
    
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
