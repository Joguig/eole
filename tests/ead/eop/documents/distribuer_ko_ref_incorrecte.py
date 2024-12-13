# -*- coding: utf-8 -*-
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.common.keys import Keys
from selenium.webdriver.support.ui import Select
from selenium.common.exceptions import NoSuchElementException
from selenium.common.exceptions import NoAlertPresentException
import unittest, time, re

class DistribuerKoRFIncorrecte(unittest.TestCase):
    def setUp(self):
        self.driver = webdriver.Firefox()
        self.driver.implicitly_wait(30)
        self.base_url = "https://bogdanov.eole.lan/"
        self.verificationErrors = []
        self.accept_next_alert = True
    
    def test_distribuer_ko_r_f_incorrecte(self):
        driver = self.driver
        driver.find_element_by_id("link-distribuer").click()
        Select(driver.find_element_by_id("groupe")).select_by_visible_text("c31")
        self.assertTrue(self.is_element_present(By.ID, "nomdev_message"))
        self.assertEqual(u"Une référence doit être fournie.", driver.find_element_by_id("nomdev_message").text)
        driver.find_element_by_id("nomdev").clear()
        driver.find_element_by_id("nomdev").send_keys("Devoir 1 test selenium")
        driver.find_element_by_link_text("Vider la liste").click()
        self.assertFalse(self.is_element_present(By.ID, "nomdev_message"))
        Select(driver.find_element_by_id("groupe")).select_by_visible_text("c31")
        self.assertTrue(self.is_element_present(By.ID, "nomdev_message"))
        self.assertEqual(u"Cette référence est déjà utilisée pour c31.", driver.find_element_by_id("nomdev_message").text)
        driver.find_element_by_id("nomdev").clear()
        driver.find_element_by_id("nomdev").send_keys("/etc/dangereuxpirate")
        Select(driver.find_element_by_id("groupe")).select_by_visible_text("c32")
        self.assertTrue(self.is_element_present(By.ID, "nomdev_message"))
        self.assertEqual(u"La référence ne doit pas contenir le caractère '/'.", driver.find_element_by_id("nomdev_message").text)
    
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
