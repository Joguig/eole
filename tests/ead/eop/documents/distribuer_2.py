# -*- coding: utf-8 -*-
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.common.keys import Keys
from selenium.webdriver.support.ui import Select
from selenium.common.exceptions import NoSuchElementException
from selenium.common.exceptions import NoAlertPresentException
import eolecitests, unittest, time, re

class DistribuerOk2(eolecitests.EoleCiTests):
    def setUp(self):
        self.driver = webdriver.Firefox()
        self.driver.implicitly_wait(30)
        self.base_url = "https://bogdanov.eole.lan/"
        self.verificationErrors = []
        self.accept_next_alert = True
    
    def test_distribuer_ok2(self):
        driver = self.driver
        driver.find_element_by_id("linkDistribuer").click()
        driver.find_element_by_id("nomdev").clear()
        driver.find_element_by_id("nomdev").send_keys("Devoir 2 test selenium")
        Select(driver.find_element_by_id("groupe")).select_by_visible_text("c31")
        Select(driver.find_element_by_id("groupe")).select_by_visible_text("c32")
        driver.find_element_by_id("eleve_only-1").click()
        driver.find_element_by_css_selector("div.plupload.html5>input:nth(0)").clear()
        driver.find_element_by_css_selector("div.plupload.html5>input:nth(0)").send_keys("~/docupload.txt")
        driver.find_element_by_css_selector("div.plupload.html5>input:nth(1)").clear()
        driver.find_element_by_css_selector("div.plupload.html5>input:nth(1)").send_keys("~/annexeupload.txt")
        driver.find_element_by_id("rep_dest-1").click()
        driver.find_element_by_id("btnSubmitDistribuer").click()
        self.assertEqual("Devoir 2 test selenium", driver.find_element_by_id("recap-ref").text)
        self.assertEqual("Distribuer plus tard", driver.find_element_by_id("recap-inperso").text)
        self.assertEqual(u"À tous les membres", driver.find_element_by_id("recap-eleveonly").text)
        self.assertEqual("c31 c32", driver.find_element_by_id("recap-groupes").text)
        self.assertEqual("docupload.txt", driver.find_element_by_id("recap-dev").text)
        self.assertEqual("annexeupload.txt", driver.find_element_by_id("recap-data").text)
        driver.find_element_by_id("recap-confirm").click()
        driver.find_element_by_link_text("Documents").click()
        driver.find_element_by_link_text("Historique").click()
        for i in range(60):
            try:
                if u"Distribué" == driver.find_element_by_xpath("//table[@id='tableauhistorique']/tbody/tr/td[4]").text: break
            except: pass
            time.sleep(1)
        else: self.fail("time out")
        self.assertEqual("devoir_2_test_selenium-c31", driver.find_element_by_xpath("//table[@id='tableauhistorique']/tbody/tr/td").text)
        self.assertEqual("c31", driver.find_element_by_xpath("//table[@id='tableauhistorique']/tbody/tr/td[2]").text)
        self.assertEqual("non", driver.find_element_by_xpath("//table[@id='tableauhistorique']/tbody/tr/td[3]").text)
        self.assertEqual(u"Distribué", driver.find_element_by_xpath("//table[@id='tableauhistorique']/tbody/tr/td[4]").text)
        self.assertEqual("Ramasser Supprimer", driver.find_element_by_xpath("//table[@id='tableauhistorique']/tbody/tr/td[5]").text)
        self.assertEqual("devoir_2_test_selenium-c32", driver.find_element_by_xpath("//table[@id='tableauhistorique']/tbody/tr[2]/td").text)
        self.assertEqual("c32", driver.find_element_by_xpath("//table[@id='tableauhistorique']/tbody/tr[2]/td[2]").text)
        self.assertEqual("non", driver.find_element_by_xpath("//table[@id='tableauhistorique']/tbody/tr[2]/td[3]").text)
        self.assertEqual(u"Distribué", driver.find_element_by_xpath("//table[@id='tableauhistorique']/tbody/tr[2]/td[4]").text)
        self.assertEqual("Ramasser Supprimer", driver.find_element_by_xpath("//table[@id='tableauhistorique']/tbody/tr[2]/td[5]").text)
    
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
