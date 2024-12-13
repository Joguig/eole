# -*- coding: utf-8 -*-
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.common.keys import Keys
from selenium.webdriver.support.ui import Select
from selenium.common.exceptions import NoSuchElementException
from selenium.common.exceptions import NoAlertPresentException
import unittest, time, re

class VRificationMailRendu(unittest.TestCase):
    def setUp(self):
        self.driver = webdriver.Firefox()
        self.driver.implicitly_wait(30)
        self.base_url = "https://bogdanov.eole.lan/"
        self.verificationErrors = []
        self.accept_next_alert = True
    
    def test_v_rification_mail_rendu(self):
        driver = self.driver
        driver.get(self.base_url + "${baseUrl}/roundcube/")
        driver.find_element_by_id("username").clear()
        driver.find_element_by_id("username").send_keys("c31e1")
        driver.find_element_by_id("password").clear()
        driver.find_element_by_id("password").send_keys("$eole123456")
        driver.find_element_by_id("valider").click()
        self.assertTrue(self.is_element_present(By.ID, "toplogo"))
        self.assertEqual("c31e1@i-etab24yo.ac-yo.fr", driver.find_element_by_css_selector("span.username").text)
        self.assertTrue(self.is_element_present(By.LINK_TEXT, "Sujet du mail de rendu"))
        try: self.assertEqual("M. Prof1", driver.find_element_by_css_selector("span.rcmContactAddress").text)
        except AssertionError as e: self.verificationErrors.append(str(e))
        driver.find_element_by_id("rcmbtn101").click()
        self.assertEqual("Authentification : Veuillez vous authentifier", driver.title)
        driver.get(self.base_url + "${baseUrl}/logout")
    
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
