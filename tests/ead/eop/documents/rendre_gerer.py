# -*- coding: utf-8 -*-
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.common.keys import Keys
from selenium.webdriver.support.ui import Select
from selenium.common.exceptions import NoSuchElementException
from selenium.common.exceptions import NoAlertPresentException
import unittest, time, re

class RendreViaRestitution(unittest.TestCase):
    def setUp(self):
        self.driver = webdriver.Firefox()
        self.driver.implicitly_wait(30)
        self.base_url = "https://bogdanov.eole.lan/"
        self.verificationErrors = []
        self.accept_next_alert = True
    
    def test_rendre_via_restitution(self):
        driver = self.driver
        driver.find_element_by_id("link-rendre").click()
        driver.find_element_by_id("ren_envoi_mail").click()
        driver.find_element_by_id("ren_sujet_mail").clear()
        driver.find_element_by_id("ren_sujet_mail").send_keys("Sujet du mail de rendu")
        driver.find_element_by_id("ren_corps_mail").clear()
        driver.find_element_by_id("ren_corps_mail").send_keys("Contenu du mail de rendu")
        Select(driver.find_element_by_id("list_dev_a_ren")).select_by_visible_text("devoir_2_test_selenium-c31")
        driver.find_element_by_id("btnSubmitRendre").click()
        driver.find_element_by_id("link-historique").click()
        for i in range(60):
            try:
                if "Rendu" == driver.find_element_by_xpath("//table[@id='tableauhistorique']/tbody/tr[2]/td[4]").text: break
            except: pass
            time.sleep(1)
        else: self.fail("time out")
        for i in range(60):
            try:
                if "Rendu" == driver.find_element_by_xpath("//table[@id='tableauhistorique']/tbody/tr[3]/td[4]").text: break
            except: pass
            time.sleep(1)
        else: self.fail("time out")
        self.assertEqual("devoir_2_test_selenium-c31", driver.find_element_by_xpath("//table[@id='tableauhistorique']/tbody/tr[3]/td").text)
        self.assertEqual("Supprimer", driver.find_element_by_xpath("//table[@id='tableauhistorique']/tbody/tr[3]/td[5]").text)
    
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
