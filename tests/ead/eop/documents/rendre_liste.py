# -*- coding: utf-8 -*-
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.common.keys import Keys
from selenium.webdriver.support.ui import Select
from selenium.common.exceptions import NoSuchElementException
from selenium.common.exceptions import NoAlertPresentException
import unittest, time, re

class RendreViaListe(unittest.TestCase):
    def setUp(self):
        self.driver = webdriver.Firefox()
        self.driver.implicitly_wait(30)
        self.base_url = "https://bogdanov.eole.lan/"
        self.verificationErrors = []
        self.accept_next_alert = True
    
    def test_rendre_via_liste(self):
        driver = self.driver
        driver.find_element_by_id("linkHistorique").click()
        for i in range(60):
            try:
                if self.is_element_present(By.LINK_TEXT, "Rendre"): break
            except: pass
            time.sleep(1)
        else: self.fail("time out")
        driver.find_element_by_xpath("(//a[contains(text(),'Rendre')])[2]").click()
        for i in range(60):
            try:
                if "Rendu" == driver.find_element_by_xpath("//table[@id='tableauhistorique']/tbody/tr/td[4]").text: break
            except: pass
            time.sleep(1)
        else: self.fail("time out")
        self.assertEqual("devoir_1_test_selenium-c31", driver.find_element_by_xpath("//table[@id='tableauhistorique']/tbody/tr/td").text)
        self.assertEqual("Supprimer", driver.find_element_by_xpath("//table[@id='tableauhistorique']/tbody/tr/td[5]").text)
    
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
