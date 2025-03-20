#!/bin/bash

echo "**** Running prebuild script to generate mod security exceptions"
rm -rf scratch/rules/modsecurity_crs_99_revscot_exceptions.conf
mkdir -p  scratch/rules/
../generate-modsecurity-exceptions.rb modsec_exceptions.yml scratch/rules/modsecurity_crs_99_revscot_exceptions.conf
