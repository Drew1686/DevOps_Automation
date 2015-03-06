#!/usr/bin/env python
# encoding: utf-8

__author__ = 'Alec'
import sys
import requests

if len(sys.argv) != 5:
   print "Incorrect arguments"
   print "Usage:   ./remove_underwriting_exception.py <identity>    <password> <quote number> <ticket number>"
   print "Example: ./remove_underwriting_exception.py me@icg360.com mypassword 557001         HELP-1404"
   exit(1)

identity = sys.argv[1]  # "alec.munro@arc90.com"
password = sys.argv[2]
quotenum = sys.argv[3]
ticket   = sys.argv[4]

BODY = """<PolicyChangeSet schemaVersion="2.1" username="{0}" description="Removing underwriting exception for ticket {1}">
  <Flags>
    <Flag name="UnderwritingExceptionAutoResolveWorkflow" value="false"/>
    <Flag name="UnderwritingExceptionEffectiveDate" value="false"/>
  </Flags>
</PolicyChangeSet>""".format(identity, ticket)

CREDS = (identity, password)

URL = "https://services.sagesure.com/cru-4/pxcentral/api/rest/v1/policies/cru4q-{0}".format(quotenum)

if __name__ == "__main__":
   response = requests.post(URL, auth=CREDS, headers={"content-type": "application/xml"}, data=BODY)
   print(response)

