# -*- coding: utf-8 -*-
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.common.keys import Keys
from selenium.webdriver.support.ui import Select
from selenium.common.exceptions import NoSuchElementException
from selenium.common.exceptions import NoAlertPresentException
import unittest, time, re

class VRifierFichiersRendusLVes(unittest.TestCase):
    def setUp(self):
        self.driver = webdriver.Firefox()
        self.driver.implicitly_wait(30)
        self.base_url = "https://bogdanov.eole.lan/"
        self.verificationErrors = []
        self.accept_next_alert = True
    
    def test_v_rifier_fichiers_rendus_l_ves(self):
        driver = self.driver
        driver.get(self.base_url + "${baseUrl}/ajaxplorer/")
        driver.find_element_by_id("username").clear()
        driver.find_element_by_id("username").send_keys("c31e1")
        driver.find_element_by_id("password").clear()
        driver.find_element_by_id("password").send_keys("$eole123456")
        driver.find_element_by_id("valider").click()
        for i in range(60):
            try:
                if self.is_element_present(By.ID, "webfx-tree-object-4-label"): break
            except: pass
            time.sleep(1)
        else: self.fail("time out")
        for i in range(60):
            try:
                if "home" == driver.find_element_by_id("webfx-tree-object-4-label").text: break
            except: pass
            time.sleep(1)
        else: self.fail("time out")
        driver.find_element_by_id("webfx-tree-object-4-label").click()
        driver.find_element_by_css_selector("img.simple_button_arrow").click()
        driver.find_element_by_id("search_txt").clear()
        driver.find_element_by_id("search_txt").send_keys("correction")
        driver.find_element_by_css_selector("#search_button > img").click()
        for i in range(60):
            try:
                if self.is_element_present(By.CSS_SELECTOR, "em"): break
            except: pass
            time.sleep(1)
        else: self.fail("time out")
        driver.find_element_by_css_selector("em").click()
        driver.find_element_by_css_selector("img.simple_button_arrow").click()
        for i in range(60):
            try:
                if "AjaXplorer - devoir_1_test_selenium-c31" == driver.title: break
            except: pass
            time.sleep(1)
        else: self.fail("time out")
        # ERROR: Caught exception [ERROR: Unsupported command [contextMenu | id=table_rows_container-1 | ]]
        for i in range(60):
            try:
                if self.is_element_present(By.ID, "action_instance_refresh"): break
            except: pass
            time.sleep(1)
        else: self.fail("time out")
        driver.find_element_by_id("action_instance_refresh").click()
        for i in range(60):
            try:
                if not self.is_element_present(By.ID, "element_overlay"): break
            except: pass
            time.sleep(1)
        else: self.fail("time out")
        # ERROR: Caught exception [ERROR: Unsupported command [contextMenu | xpath=(//span[@id='ajxp_label'])[1] | ]]
        for i in range(60):
            try:
                if self.is_element_present(By.CSS_SELECTOR, "li > #action_instance_ls"): break
            except: pass
            time.sleep(1)
        else: self.fail("time out")
        driver.find_element_by_css_selector("li > #action_instance_ls").click()
        for i in range(60):
            try:
                if "AjaXplorer - correction" == driver.title: break
            except: pass
            time.sleep(1)
        else: self.fail("time out")
        self.assertEqual("docupload.txt", driver.find_element_by_xpath("(//span[@id='ajxp_label'])[2]").text)
        self.assertEqual("fichier_eleve.txt", driver.find_element_by_xpath("(//span[@id='ajxp_label'])[3]").text)
        self.assertEqual("fichier_prof_rendu.txt", driver.find_element_by_xpath("(//span[@id='ajxp_label'])[4]").text)
        # ERROR: Caught exception [ERROR: Unsupported command [contextMenu | xpath=(//span[@id='ajxp_label'])[1] | ]]
        for i in range(60):
            try:
                if self.is_element_present(By.CSS_SELECTOR, "li > #action_instance_ls"): break
            except: pass
            time.sleep(1)
        else: self.fail("time out")
        driver.find_element_by_css_selector("li > #action_instance_ls").click()
        for i in range(60):
            try:
                if "AjaXplorer - dossier_eleve" == driver.title: break
            except: pass
            time.sleep(1)
        else: self.fail("time out")
        self.assertEqual("fichier_eleve_dans_dossier.txt", driver.find_element_by_xpath("(//span[@id='ajxp_label'])[1]").text)
        self.assertEqual("fichier_prof_a_rendre.txt", driver.find_element_by_xpath("(//span[@id='ajxp_label'])[2]").text)
        driver.find_element_by_id("logout_button_label").click()
        self.assertEqual("Authentification : Veuillez vous authentifier", driver.title)
        driver.get(self.base_url + "${baseUrl}:8443/logout")
    
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
