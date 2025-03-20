--***********************************************************************
-- File    : RSTP_seeded_test_data.sql
-- Purpose : 
--    This script creates data for testing of the revenues scotland 
--    portal
-- 
--   The script should be run on the Back Office as the revscot user
--
--***********************************************************************

set serverout on
set define off

exec fl_variables.set_g_username('EXTPWSUSER');

UPDATE http_details
SET http_target_host_url = REPLACE(REPLACE(http_target_host_url,'<server>','ps-ndips-qa'),'<port>','8018')
WHERE http_description like 'NDIPS%'
AND http_target_host_url like '%<server>:<port>%';

UPDATE parameters
SET prm_value = 'N'
WHERE prm_code = 'IS_2FA_ENABLED'
AND prm_domain = 'PWS';

UPDATE parameters
SET prm_value = 'N'
WHERE prm_code = 'ENABLE_BO_2FA'
AND prm_domain = 'SYSTEM';

DECLARE
 l_db_name VARCHAR2(500);
BEGIN

SELECT NAME
INTO l_db_name
FROM v$database;

DELETE parameters
WHERE prm_domain IN ('BANNER MESSAGE','BANNER COLOUR');

INSERT INTO parameters( prm_domain
                     , prm_code
                     , prm_start_date
                     , prm_datatype
                     , prm_value
                     , prm_description
                     , prm_act_code)
SELECT  'BANNER MESSAGE'
      ,l_db_name
      , TO_DATE('01-APR-1990', 'DD-MON-RRRR')
      , 'C'
      ,'The description text shown on the environment banner'
      ,'The description text shown on the environment banner'
      ,'UPBANNER'
FROM dual
WHERE NOT EXISTS( SELECT 1
                 FROM parameters 
                 WHERE prm_domain = 'BANNER MESSAGE'
                 AND prm_code = l_db_name
                 AND prm_start_date = TO_DATE('01-APR-1990', 'DD-MON-RRRR'));

INSERT INTO parameters( prm_domain
                     , prm_code
                     , prm_start_date
                     , prm_datatype
                     , prm_value
                     , prm_description
                     , prm_act_code)
SELECT  'BANNER COLOUR'
      , l_db_name
      , TO_DATE('01-APR-1990', 'DD-MON-RRRR')
      , 'C'
      ,'FF0000'
      ,'The background hex colour of the banner for '||l_db_name
      ,'UPBANNER'
FROM dual
WHERE NOT EXISTS( SELECT 1
                 FROM parameters 
                 WHERE prm_domain = 'BANNER COLOUR'
                 AND prm_code = l_db_name
                 AND prm_start_date = TO_DATE('01-APR-1990', 'DD-MON-RRRR'));
EXCEPTION 
WHEN OTHERS THEN NULL;
END;
/


UPDATE fl_ref_values
SET frv_code = 'ACCSECADMN'
WHERE frv_code IN ('ACCSEC','ACCSECADM')
AND frv_frd_domain = 'PORTALROLES';

UPDATE workplace_service_parameters
SET wsp_value = 1
WHERE wsp_srv_code = 'LBTT'
AND wsp_wrk_refno = 1
AND wsp_sprm_code in ('PWS_WARN_FUTURE_DAYS');

UPDATE workplace_service_parameters
SET wsp_value = 28
WHERE wsp_srv_code = 'LBTT'
AND wsp_wrk_refno = 1
AND wsp_sprm_code in ('PWS_WARN_PAST_DAYS');


DECLARE

  l_par_refno parties.par_refno%TYPE; -- used to hold the current party reference
  l_par_refno_temp parties.par_refno%TYPE; -- used to hold the current party reference (changing)
  l_par_refno_new parties.par_refno%TYPE; -- used to hold the current party reference
  l_tare_refno tax_returns.tare_refno%TYPE; -- used to hold the current tax reference
  l_last_refno integer := 0; -- used to roll the sequence on for sites
  l_tmp_par_refno parties.par_refno%TYPE; -- used to hold the current party reference for buyers and sellers
  l_pro_refno properties.pro_refno%TYPE; -- property for LBTT
  l_h_version INTEGER; -- temp version number
  l_fiac_refno financial_accounts.fiac_refno%TYPE; -- Financial account
  l_ltra_refno transactions.tra_refno%TYPE; -- liable transaction used for creating match
  l_ptra_refno transactions.tra_refno%TYPE; -- payment transaction for match
  l_orig_smsg_refno secure_messages.smsg_refno%TYPE; -- original message reference
  l_smsg_refno secure_messages.smsg_refno%TYPE; -- message reference for fiddling date
  l_case_refno cases.case_refno%TYPE; -- case refno (for messages)
  l_adr_refno addresses.adr_refno%TYPE; -- adr refno for ADS main address
  l_trs_refno tax_return_schedules.trs_refno%TYPE; -- tax return schedule refno
  l_strp_refno schd_type_return_periods.strp_refno%TYPE; -- strp refno for schedule type return periods
  l_taxl_refno1 taxable_locations.taxl_refno%TYPE; -- Taxable locations (sites) refno
  l_taxl_refno2 taxable_locations.taxl_refno%TYPE; -- Taxable locations (sites) refno
  l_tld_refno trv_location_details.tld_refno%TYPE; -- location details refno
  l_ep_refno         NUMBER;
  l_enrm_refno       NUMBER;
  l_aggr_par_refno   NUMBER;
  l_enr_par_refno    NUMBER;
  l_strp_seq         NUMBER;
  l_srpb_seq         NUMBER;
  l_taxl_refno_seq   NUMBER;

  -- The amendable and non amendable date need to be updated once a year at the beginning of august
  -- Then update the same dates in the dashboard_returns.feature
  -- Also update the dates in the lbtt_returns.feature file
  AMENDABLE_DATE VARCHAR2(12) := '01-JUL-2024';
  NON_AMENDABLE_DATE VARCHAR2(12) := '01-JUN-2022';
  -- This is set to a few days before the amendable date for older versions
  SLFT_SUBMITTED_DATE VARCHAR2(12) := '19-JUN-2024';
  SLFT_AMENDABLE_YEAR VARCHAR2(4) := '2024';
  
      PROCEDURE create_or_maintain_cde(p_par_refno parties.par_refno%TYPE,
         p_cde_cme_code contact_details.cde_cme_code%TYPE,
         p_value contact_details.cde_contact_value%TYPE)
      IS
      
         CURSOR c_check_cde
         IS
         SELECT cde_refno
         FROM contact_details
         WHERE cde_object_reference = p_par_refno
           AND cde_cme_code = p_cde_cme_code
           AND TRUNC(SYSDATE) BETWEEN cde_start_date AND NVL(cde_end_date,TRUNC(SYSDATE));

         ln_cde_ref contact_details.cde_refno%TYPE;
         l_cde_refno contact_details.cde_refno%TYPE;
      BEGIN
         OPEN c_check_cde;
         FETCH c_check_cde INTO ln_cde_ref;
         IF c_check_cde%NOTFOUND
         THEN
            l_cde_refno := cde_refno.nextval;
            INSERT INTO contact_details
               (cde_refno,cde_cme_code,cde_frv_fao_code,cde_object_reference,cde_start_date,cde_contact_value)
            VALUES
               (l_cde_refno,p_cde_cme_code,'PAR',p_par_refno,TRUNC(SYSDATE),p_value);
            dbms_output.put_line('Inserted CDE : '||p_cde_cme_code||' '||p_value);

            INSERT INTO contact_details_history
               (cdeh_refno, cdeh_cme_code, cdeh_frv_fao_code, cdeh_object_reference, cdeh_object_version, cdeh_contact_value, cdeh_primary_ind, cdeh_srv_code,cmeh_cde_refno)
            VALUES
               (cdeh_seq.nextval,p_cde_cme_code,'PAR',p_par_refno,1,p_value,'Y','SYS',l_cde_refno);
         ELSE
            UPDATE contact_details
            SET cde_contact_value = p_value
            WHERE cde_refno = ln_cde_ref;
            dbms_output.put_line('Updated CDE : '||p_cde_cme_code||' '||p_value);
         END IF;
         CLOSE c_check_cde;

      END;
      
        PROCEDURE create_or_maintain_address(p_refno address_usages.aus_object_reference%TYPE
         ,p_fao_code address_usages.aus_aut_frv_fao_code%TYPE
         ,p_adr_address_line_1 addresses.adr_address_line_1%TYPE
         ,p_adr_address_line_2 addresses.adr_address_line_2%TYPE
         ,p_adr_town addresses.adr_town%TYPE
         ,p_adr_county addresses.adr_county%TYPE
         ,p_adr_postcode addresses.adr_postcode%TYPE
		     ,p_adr_type VARCHAR2 DEFAULT 'CORR'
         ,p_adr_country addresses.adr_country%TYPE DEFAULT 'GB')
      IS
      
         CURSOR c_check_aus
         IS
         SELECT aus_adr_refno
         FROM address_usages
         WHERE aus_aut_frv_fao_code = p_fao_code
           AND aus_aut_frv_far_code = p_adr_type
           AND aus_object_reference = p_refno
           AND TRUNC(SYSDATE) BETWEEN aus_start_date AND NVL(aus_end_date,TRUNC(SYSDATE));

         ln_adr_ref address_usages.aus_adr_refno%TYPE;
      BEGIN
         OPEN c_check_aus;
         FETCH c_check_aus INTO ln_adr_ref;
         IF c_check_aus%NOTFOUND
         THEN
            INSERT INTO addresses
               (adr_refno,adr_address_line_1,adr_address_line_2,adr_town,adr_postcode,adr_county,adr_country)
            VALUES
               (adr_seq.nextval,p_adr_address_line_1,p_adr_address_line_2,p_adr_town,p_adr_postcode,p_adr_county,p_adr_country)
            RETURNING adr_refno INTO ln_adr_ref;
               
            INSERT INTO address_usages
               (aus_aut_frv_fao_code,aus_aut_frv_far_code,aus_object_reference,aus_start_date,aus_adr_refno,aus_srv_code)
            VALUES
               (p_fao_code,p_adr_type ,p_refno,TRUNC(SYSDATE),ln_adr_ref,'SYS');
               
            dbms_output.put_line('Inserted ADR : '||p_adr_address_line_1||' '||p_adr_postcode||' '||ln_adr_ref);

         ELSE
            UPDATE address_usages
            SET aus_srv_code = 'SYS'
            WHERE aus_aut_frv_fao_code = p_fao_code
              AND aus_aut_frv_far_code = p_adr_type
              AND aus_object_reference = p_refno
              AND TRUNC(SYSDATE) BETWEEN aus_start_date AND NVL(aus_end_date,TRUNC(SYSDATE));
            
            UPDATE addresses
            SET adr_address_line_1=p_adr_address_line_1
               ,adr_address_line_2=p_adr_address_line_2
               ,adr_town=p_adr_town
               ,adr_county=p_adr_county
               ,adr_postcode=adr_postcode
            WHERE adr_refno = ln_adr_ref;
            dbms_output.put_line('Updated ADR : '||p_adr_address_line_1||' '||p_adr_postcode||' '||ln_adr_ref);
         END IF;
         CLOSE c_check_aus;
      END;  

BEGIN
  fl_variables.set_g_username('EXTPWSUSER');
  
  -- Some of the below isn't production but it does the trick!
  -- Delete any PWS system notices
  DELETE FROM system_notices WHERE syno_system = 'PWS';

  -- Delete the test portal company
  DELETE FROM document_notes WHERE dno_created_by IN (SELECT usr_refno from users WHERE usr_par_refno IN (SELECT par_refno FROM parties WHERE par_com_company_name like 'Test Portal Company%'));
  DELETE FROM user_services WHERE use_username IN (SELECT usr_username from users WHERE usr_par_refno IN (SELECT par_refno FROM parties WHERE par_com_company_name like 'Test Portal Company%'));
  DELETE FROM audit_logs WHERE alg_usr_usr_username IN (SELECT usr_username from users WHERE usr_par_refno IN (SELECT par_refno FROM parties WHERE par_com_company_name like 'Test Portal Company%'));
  DELETE FROM role_users WHERE rus_usr_username IN (SELECT usr_username from users WHERE usr_par_refno IN (SELECT par_refno FROM parties WHERE par_com_company_name like 'Test Portal Company%'));
  DELETE FROM DOCUMENT_ACTIVITY_AUDIT where daa_to_be_received_by in
     (select usr_refno FROM users WHERE usr_par_refno IN (SELECT par_refno FROM parties WHERE par_com_company_name like 'Test Portal Company%'));
  DELETE FROM FWF_ALLOCATIONS WHERE fal_usr_username IN (select usr_username FROM users WHERE usr_par_refno IN (SELECT par_refno FROM parties WHERE par_com_company_name like 'Test Portal Company%'));
  
  DELETE from PORTAL_OBJECT_ACCESS where POA_PORTAL_PAR_REFNO in (select usr_par_refno FROM users WHERE usr_par_refno IN (SELECT par_refno FROM parties WHERE par_com_company_name like 'Test Portal Company%'));
  
  DELETE FROM users WHERE usr_par_refno IN (SELECT par_refno FROM parties WHERE par_com_company_name like 'Test Portal Company%');
  DELETE FROM secure_messages WHERE smsg_par_refno IN (SELECT par_refno FROM parties WHERE par_com_company_name like 'Test Portal Company%');
  DELETE FROM address_usages WHERE aus_object_reference IN (SELECT par_refno FROM parties WHERE par_com_company_name like 'Test Portal Company%');
  
  -- Delete from SLFT Data
  DELETE FROM slft_site_details WHERE slsd_lasi_refno IN (SELECT lasi_refno FROM landfill_sites WHERE lasi_controller_par_refno IN (SELECT par_refno FROM parties WHERE par_com_company_name like 'Test Portal Company%')
                                                UNION ALL SELECT 99 from dual UNION ALL SELECT 100 from dual);
  DELETE FROM slft_site_details_breakdown WHERE slsb_lasi_refno IN (SELECT lasi_refno FROM landfill_sites WHERE lasi_controller_par_refno IN (SELECT par_refno FROM parties WHERE par_com_company_name like 'Test Portal Company%')
                                                UNION ALL SELECT 99 from dual UNION ALL SELECT 100 from dual);
  DELETE FROM slft_returns WHERE slft_par_refno IN (SELECT par_refno FROM parties WHERE par_com_company_name like 'Test Portal Company%');
  DELETE FROM case_return_links WHERE crli_tare_refno IN (SELECT tare_refno FROM tax_returns WHERE tare_srv_code = 'SLFT' and NOT EXISTS 
      (SELECT NULL FROM slft_returns WHERE slft_tare_refno = tare_refno));
  DELETE FROM return_repayments WHERE rrep_tare_refno IN (SELECT tare_refno FROM tax_returns WHERE tare_srv_code = 'SLFT' and NOT EXISTS 
      (SELECT NULL FROM slft_returns WHERE slft_tare_refno = tare_refno));
  DELETE FROM tax_returns WHERE tare_srv_code = 'SLFT' and NOT EXISTS (SELECT NULL FROM slft_returns WHERE slft_tare_refno = tare_refno);

  -- Delete LBTT Data
  DELETE FROM lbtt_properties;         
  DELETE FROM lbtt_return_party_links WHERE lpli_lbtt_tare_refno IN (
       SELECT lpli_lbtt_tare_refno FROM lbtt_return_party_links WHERE lpli_flpt_type = 'AGENT' AND lpli_par_refno IN 
         (SELECT par_refno FROM parties WHERE par_com_company_name like 'Test Portal Company%'));
  DELETE FROM lbtt_yearly_rents WHERE lbyr_lbtt_tare_refno IN (
       SELECT lpli_lbtt_tare_refno FROM lbtt_return_party_links WHERE lpli_flpt_type = 'AGENT' AND lpli_par_refno IN 
         (SELECT par_refno FROM parties WHERE par_com_company_name like 'Test Portal Company%'));
  DELETE FROM lbtt_yearly_rents WHERE lbyr_lbtt_tare_refno IN (
        SELECT tare_refno FROM tax_returns WHERE tare_reference = 'RS2000003BBBB');
  DELETE FROM lbtt_tax_return_links WHERE lbtr_tare_refno IN (
       SELECT lpli_lbtt_tare_refno FROM lbtt_return_party_links WHERE lpli_flpt_type = 'AGENT' AND lpli_par_refno IN 
         (SELECT par_refno FROM parties WHERE par_com_company_name like 'Test Portal Company%'));
  DELETE FROM lbtt_tax_return_links WHERE lbtr_lbtt_tare_refno IN (
       SELECT lpli_lbtt_tare_refno FROM lbtt_return_party_links WHERE lpli_flpt_type = 'AGENT' AND lpli_par_refno IN 
         (SELECT par_refno FROM parties WHERE par_com_company_name like 'Test Portal Company%'));         
  DELETE FROM lbtt_reliefs WHERE lbrl_lbtt_tare_refno IN (
       SELECT lpli_lbtt_tare_refno FROM lbtt_return_party_links WHERE lpli_flpt_type = 'AGENT' AND lpli_par_refno IN 
         (SELECT par_refno FROM parties WHERE par_com_company_name like 'Test Portal Company%'));
  DELETE FROM addresses WHERE adr_refno IN (
       SELECT lbtt_ads_main_adr_refno FROM lbtt_returns JOIN lbtt_return_party_links ON (lpli_lbtt_tare_refno = lbtt_tare_refno)WHERE lpli_flpt_type = 'AGENT' AND lpli_par_refno IN 
         (SELECT par_refno FROM parties WHERE par_com_company_name like 'Test Portal Company%'));
  -- Delete orphaned returns
  DELETE FROM lbtt_returns
  WHERE NOT EXISTS (SELECT NULL FROM lbtt_return_party_links WHERE lpli_lbtt_tare_refno = lbtt_tare_refno)
    AND NOT EXISTS (SELECT NULL FROM lbtt_properties WHERE lppr_lbtt_tare_refno = lbtt_tare_refno)
    AND NOT EXISTS (SELECT NULL FROM lbtt_yearly_rents WHERE lbyr_lbtt_tare_refno = lbtt_tare_refno)
    AND NOT EXISTS (SELECT NULL FROM lbtt_tax_return_links WHERE lbtr_lbtt_tare_refno = lbtt_tare_refno)
    AND NOT EXISTS (SELECT NULL FROM lbtt_reliefs WHERE lbrl_lbtt_tare_refno = lbtt_tare_refno);
  DELETE FROM lbtt_tax_return_links WHERE lbtr_tare_refno IN (SELECT tare_refno
     FROM tax_returns WHERE tare_srv_code = 'LBTT' and NOT EXISTS (SELECT NULL FROM lbtt_returns WHERE lbtt_tare_refno = tare_refno));
  DELETE FROM case_return_links WHERE crli_tare_refno IN (SELECT tare_refno FROM tax_returns WHERE tare_srv_code = 'LBTT' and NOT EXISTS 
      (SELECT NULL FROM lbtt_returns WHERE lbtt_tare_refno = tare_refno));
  DELETE FROM return_repayments WHERE rrep_tare_refno IN (SELECT tare_refno FROM tax_returns WHERE tare_srv_code = 'LBTT' and NOT EXISTS 
      (SELECT NULL FROM lbtt_returns WHERE lbtt_tare_refno = tare_refno));
  DELETE FROM tax_returns WHERE tare_srv_code = 'LBTT' and NOT EXISTS (SELECT NULL FROM lbtt_returns WHERE lbtt_tare_refno = tare_refno);
  DELETE FROM contact_details_history WHERE NOT EXISTS (SELECT null FROM contact_details WHERE cde_frv_fao_code = 'PAR' AND cde_object_reference = cmeh_cde_refno);
  DELETE FROM contact_details WHERE cde_frv_fao_code = 'PAR' AND NOT EXISTS (SELECT null FROM parties WHERE par_refno = cde_object_reference);
  
  -- Delete financial_transactions
  DELETE FROM transaction_matches WHERE tram_credit_tra_refno IN 
   (SELECT tra_refno FROM transactions WHERE tra_fiac_refno IN
      (SELECT fpli_fiac_refno FROM fiac_party_links WHERE fpli_par_refno IN 
        (SELECT par_refno FROM parties WHERE par_com_company_name like 'Test Portal Company%' )));
  DELETE FROM transaction_matches WHERE tram_debit_tra_refno IN 
   (SELECT tra_refno FROM transactions WHERE tra_fiac_refno IN
      (SELECT fpli_fiac_refno FROM fiac_party_links WHERE fpli_par_refno IN 
        (SELECT par_refno FROM parties WHERE par_com_company_name like 'Test Portal Company%' )));
  DELETE FROM transaction_matches WHERE tram_created_by = 'PORTAL.SAT.TAXPAYER';
  DELETE FROM transactions WHERE tra_fiac_refno IN
      (SELECT fpli_fiac_refno FROM fiac_party_links WHERE fpli_par_refno IN 
        (SELECT par_refno FROM parties WHERE par_com_company_name like 'Test Portal Company%' ));
  DELETE FROM transactions WHERE tra_fiac_refno IN
      (SELECT fpli_fiac_refno FROM fiac_party_links WHERE fpli_par_refno IN 
        (SELECT par_refno FROM parties WHERE par_org_name IN('Marks & Spencer Group','Black Sands Group','Kevin Peterson Partnership','Jim and James Group')));
  DELETE FROM transactions WHERE tra_tty_srv_code = 'SAT';
   delete from fiac_party_links where fpli_fiac_refno in 
   ( select fiac_refno from financial_accounts 
   where not exists (select 1 from tax_returns where tare_reference= fiac_reference) );
  DELETE FROM fiac_party_links WHERE fpli_par_refno IN 
        (SELECT par_refno FROM parties WHERE par_com_company_name like 'Test Portal Company%' );
  DELETE FROM fiac_party_links WHERE fpli_created_by = 'EXTPWSUSER';
  DELETE FROM fiac_party_links WHERE fpli_created_by = 'PORTAL.SAT.ONE';


  -- Delete the rest of the party data
  DELETE FROM landfill_sites WHERE lasi_controller_par_refno IN (SELECT par_refno FROM parties WHERE par_com_company_name like 'Test Portal Company%');
  DELETE FROM landfill_sites WHERE lasi_refno IN (99,100);
  DELETE FROM case_party_links WHERE cpli_par_refno IN (SELECT par_refno FROM parties WHERE par_com_company_name like 'Test Portal Company%');
  DELETE FROM lbtt_return_party_links WHERE lpli_par_refno IN (SELECT par_refno FROM parties WHERE par_com_company_name like 'Test Portal Company%');
  DELETE FROM secure_messages WHERE smsg_par_refno IN (SELECT par_refno FROM parties WHERE par_com_company_name like 'Test Portal Company%');
  DELETE FROM dd_instructions WHERE din_par_refno IN (SELECT par_refno FROM parties WHERE par_com_company_name like 'Test Portal Company%');
  DELETE FROM dd_instructions WHERE din_par_refno IN (SELECT par_refno FROM parties WHERE par_org_name like '%Kevin Peterson Partnership%');
  DELETE FROM return_repayments WHERE rrep_claimant_par_refno IN (SELECT par_refno FROM parties WHERE par_com_company_name like 'Test Portal Company%');
  DELETE FROM return_repayments WHERE rrep_par_refno IN (SELECT par_refno FROM parties WHERE par_com_company_name like 'Test Portal Company%');
  DELETE FROM contact_details WHERE cde_object_reference IN (SELECT par_refno FROM parties WHERE par_com_company_name like 'Test Portal Company%');
  DELETE FROM case_return_links WHERE crli_case_refno in (SELECT case_refno FROM cases WHERE case_created_by = 'EXTPWSUSER');
  DELETE FROM case_links WHERE cali_case_refno IN (SELECT case_refno FROM cases WHERE case_reference LIKE 'PORTAL.%');
  DELETE FROM cases WHERE case_reference LIKE 'PORTAL.%' OR  case_created_by = 'EXTPWSUSER';
  DELETE FROM alternate_references WHERE alre_alrt_object_type = 'PAR' AND alre_object_reference in (SELECT par_refno FROM parties WHERE par_com_company_name like 'Test Portal Company%');
  DELETE FROM parties WHERE par_com_company_name like 'Test Portal Company%';

  DELETE FROM document_notes WHERE dno_created_by IN (SELECT usr_refno from users WHERE usr_par_refno IN (SELECT par_refno FROM parties WHERE UPPER(par_com_company_name) like 'NORTHGATE PUBLIC SERVICES LIMITED%'));
  DELETE FROM user_services WHERE use_username IN (SELECT usr_username from users WHERE usr_par_refno IN (SELECT par_refno FROM parties WHERE UPPER(par_com_company_name) like 'NORTHGATE PUBLIC SERVICES LIMITED%'));
  DELETE FROM audit_logs WHERE alg_usr_usr_username IN (SELECT usr_username from users WHERE usr_par_refno IN (SELECT par_refno FROM parties WHERE UPPER(par_com_company_name) like 'NORTHGATE PUBLIC SERVICES LIMITED%%'));
  DELETE FROM role_users WHERE rus_usr_username IN (SELECT usr_username from users WHERE usr_par_refno IN (SELECT par_refno FROM parties WHERE UPPER(par_com_company_name) like 'NORTHGATE PUBLIC SERVICES LIMITED%%'));
  DELETE FROM users WHERE usr_par_refno IN (SELECT par_refno FROM parties WHERE UPPER(par_com_company_name) like 'NORTHGATE PUBLIC SERVICES LIMITED%%');
  DELETE FROM secure_messages WHERE smsg_par_refno IN (SELECT par_refno FROM parties WHERE UPPER(par_com_company_name) like 'NORTHGATE PUBLIC SERVICES LIMITED%%');
  DELETE FROM address_usages WHERE aus_object_reference IN (SELECT par_refno FROM parties WHERE UPPER(par_com_company_name) like 'NORTHGATE PUBLIC SERVICES LIMITED%%');
  DELETE FROM contact_details WHERE cde_object_reference IN (SELECT par_refno FROM parties WHERE UPPER(par_com_company_name) like 'NORTHGATE PUBLIC SERVICES LIMITED%%');
  DELETE FROM case_party_links WHERE cpli_par_refno IN (SELECT par_refno FROM parties WHERE UPPER(par_com_company_name) like 'NORTHGATE PUBLIC SERVICES LIMITED%%');
  DELETE FROM lbtt_return_party_links WHERE lpli_par_refno IN (SELECT par_refno FROM parties WHERE UPPER(par_com_company_name) like 'NORTHGATE PUBLIC SERVICES LIMITED%%');
  DELETE FROM alternate_references WHERE alre_alrt_object_type = 'PAR' AND alre_object_reference in (SELECT par_refno FROM parties WHERE UPPER(par_com_company_name) like 'NORTHGATE PUBLIC SERVICES LIMITED%');
  DELETE FROM fiac_party_links WHERE fpli_par_refno IN 
        (SELECT par_refno FROM parties WHERE UPPER(par_com_company_name) like 'NORTHGATE PUBLIC SERVICES LIMITED%' );
  DELETE FROM parties WHERE UPPER(par_com_company_name) like 'NORTHGATE PUBLIC SERVICES LIMITED%';
  
  DELETE FROM document_notes WHERE dno_created_by IN (SELECT usr_refno from users WHERE usr_par_refno IN (SELECT par_refno FROM parties WHERE par_per_surname like 'Port%-Test%'));
  DELETE FROM user_services WHERE use_username IN (SELECT usr_username from users WHERE usr_par_refno IN (SELECT par_refno FROM parties WHERE par_per_surname like 'Port%-Test%'));
  DELETE FROM audit_logs WHERE alg_usr_usr_username IN (SELECT usr_username from users WHERE usr_par_refno IN (SELECT par_refno FROM parties WHERE par_per_surname like 'Port%-Test%'));
  DELETE FROM role_users WHERE rus_usr_username IN (SELECT usr_username from users WHERE usr_par_refno IN (SELECT par_refno FROM parties WHERE par_per_surname like 'Port%-Test%'));
  DELETE FROM users WHERE usr_par_refno IN (SELECT par_refno FROM parties WHERE par_per_surname like 'Port%-Test%');
  DELETE FROM secure_messages WHERE smsg_par_refno IN (SELECT par_refno FROM parties WHERE par_per_surname like 'Port%-Test%');
  DELETE FROM address_usages WHERE aus_object_reference IN (SELECT par_refno FROM parties WHERE par_per_surname like 'Port%-Test%');
  DELETE FROM case_party_links WHERE cpli_par_refno IN (SELECT par_refno FROM parties WHERE par_per_surname like 'Port%-Test%');
  DELETE FROM lbtt_return_party_links WHERE lpli_par_refno IN (SELECT par_refno FROM parties WHERE par_per_surname like 'Port%-Test%');
   
  DELETE FROM fiac_party_links WHERE fpli_par_refno IN 
        (SELECT par_refno FROM parties WHERE par_per_surname like 'Port%-Test%' );
  DELETE FROM return_repayments WHERE rrep_par_refno IN (SELECT par_refno FROM parties WHERE par_per_surname like 'Port%-Test%');
  DELETE FROM contact_details WHERE cde_object_reference IN (SELECT par_refno FROM parties WHERE par_per_surname like 'Port%-Test%');
  DELETE FROM alternate_references WHERE alre_alrt_object_type = 'PAR' AND alre_object_reference in (SELECT par_refno FROM parties WHERE par_per_surname like 'Port%-Test%');
  DELETE FROM parties WHERE par_per_surname like 'Port%-Test%';
 
  -- Tidy up cases and any uploaded documents create by e.g. claims
  DELETE FROM transactions WHERE tra_case_refno in (SELECT case_refno FROM cases WHERE case_created_by LIKE 'PORTAL.%');
  DELETE FROM potential_transactions;
  DELETE FROM secure_messages WHERE smsg_case_refno in (SELECT case_refno FROM cases WHERE case_created_by LIKE 'PORTAL.%');
  DELETE FROM case_links WHERE cali_to_case_refno in (SELECT case_refno FROM cases WHERE case_created_by LIKE 'PORTAL.%');
  DELETE FROM case_links WHERE cali_case_refno in (SELECT case_refno FROM cases WHERE case_created_by LIKE 'PORTAL.%');
  DELETE FROM case_status_histories WHERE cash_case_refno in (SELECT case_refno FROM cases WHERE case_created_by LIKE 'PORTAL.%');
  DELETE FROM case_return_links WHERE crli_case_refno in (SELECT case_refno FROM cases WHERE case_created_by LIKE 'PORTAL.%');
                        
  DELETE FROM document_pages WHERE dpa_doc_refno IN (SELECT ere_doc_refno FROM external_references WHERE ere_est_code = 'CASE' 
    AND NOT EXISTS (SELECT null FROM cases where case_reference = ere_value));
  DELETE FROM external_references WHERE ere_est_code != 'CASE' AND ere_doc_refno IN (SELECT ere_doc_refno FROM external_references WHERE ere_est_code = 'CASE' 
    AND NOT EXISTS (SELECT null FROM cases where case_reference = ere_value));
  DELETE FROM document_activity_audit WHERE daa_doc_refno IN (SELECT ere_doc_refno FROM external_references WHERE ere_est_code = 'CASE' 
    AND NOT EXISTS (SELECT null FROM cases where case_reference = ere_value));
  DELETE FROM fwf_allocations WHERE fal_doc_refno IN (SELECT ere_doc_refno FROM external_references WHERE ere_est_code = 'CASE' 
    AND NOT EXISTS (SELECT null FROM cases where case_reference = ere_value));
  DELETE FROM external_references WHERE ere_est_code = 'CASE' 
    AND NOT EXISTS (SELECT null FROM cases where case_reference = ere_value);
  DELETE FROM documents WHERE NOT EXISTS (SELECT NULL FROM external_references WHERE ere_doc_refno = doc_refno);

  DELETE FROM TAX_RETURN_SCHEDULE_TYPES
  where TRST_CREATED_BY = 'EXTPWSUSER';
  
  DELETE from TAX_RETURN_PARTY_LINKS where TRPL_CREATED_BY in('EXTPWSUSER','PORTAL.SAT.TAXPAYER');
  
  DELETE from TRD_LOCATION_BREAKDOWN where TLB_CREATED_BY in ((select usr_username FROM users WHERE usr_par_refno IN (SELECT par_refno FROM parties WHERE par_com_company_name like 'Test Portal Company%')), 'EXTPWSUSER', 'PORTAL.SAT.ONE','PORTAL.SAT.TAXPAYER');
  
  DELETE from TRV_LOCATION_DETAILS where TLD_CREATED_BY in ((select usr_username FROM users WHERE usr_par_refno IN (SELECT par_refno FROM parties WHERE par_com_company_name like 'Test Portal Company%')), 'EXTPWSUSER', 'PORTAL.SAT.ONE', 'PORTAL.SAT.TAXPAYER');

  UPDATE tax_return_schedules
  SET trs_tare_refno = NULL
  WHERE TRS_CREATED_BY = 'EXTPWSUSER';

  DELETE FROM case_return_links WHERE crli_tare_refno IN (SELECT tare_refno FROM tax_returns WHERE tare_srv_code = 'SAT' and NOT EXISTS 
      (SELECT NULL FROM tax_return_versions WHERE trv_tare_refno = tare_refno));

  UPDATE tax_return_versions
  SET TRV_CASE_REFNO = NULL
  WHERE TRV_CREATED_BY LIKE 'PORTAL.%';
  
  DELETE tax_return_versions
  WHERE trv_created_by IN('EXTPWSUSER','PORTAL.SAT.TAXPAYER');
  
  DELETE FROM case_party_links WHERE cpli_case_refno in (SELECT case_refno FROM cases WHERE case_created_by LIKE 'PORTAL.%');
  DELETE FROM case_party_links WHERE cpli_par_refno IN (SELECT par_refno FROM parties WHERE par_org_name like 'Jim and James Group%');
  DELETE FROM case_party_links WHERE cpli_par_refno IN (SELECT par_refno FROM parties WHERE par_org_name like 'Marks & Spencer%');
  DELETE FROM cases WHERE case_created_by LIKE 'PORTAL.%';
  DELETE FROM cases WHERE case_related_reference = 'RS10000001GLVD';

  UPDATE tax_returns
  SET tare_fiac_refno = NULL
  WHERE tare_created_by = 'EXTPWSUSER';
  
  DELETE FROM tax_returns WHERE tare_srv_code = 'SAT' and NOT EXISTS (SELECT NULL FROM tax_return_versions WHERE trv_tare_refno = tare_refno);
  
  DELETE FROM financial_accounts WHERE fiac_reference LIKE 'PORTAL%' AND FIAC_SRV_CODE  = 'SAT';
  DELETE FROM financial_accounts WHERE fiac_created_by = 'EXTPWSUSER' AND fiac_srv_code = 'SAT';
  DELETE FROM financial_accounts WHERE fiac_reference LIKE 'PORTAL%';
  DELETE FROM financial_accounts WHERE 
     fiac_refno NOT IN (SELECT fpli_fiac_refno FROM fiac_party_links
                        UNION ALL SELECT tra_fiac_refno FROM transactions
                        UNION ALL SELECT tare_fiac_refno FROM tax_returns);
  
  DELETE FROM taxable_locations
  WHERE taxl_created_by = 'EXTPWSUSER';
  
  DELETE FROM schd_returns_period_breakdown
  WHERE srpb_created_by = 'EXTPWSUSER'; 
  
  DELETE FROM tax_return_schedules
  WHERE trs_created_by = 'EXTPWSUSER'; 
  
  DELETE FROM schd_type_return_periods
  WHERE strp_created_by = 'EXTPWSUSER'; 
  
  DELETE FROM ENROLMENT_PERIOD_PARTIES
  WHERE  epp_created_by = 'EXTPWSUSER';
  
  DELETE FROM ENROLMENT_PERIODS
  WHERE  ep_created_by = 'EXTPWSUSER';
  
  DELETE FROM enrolment_master
  WHERE  enrm_created_by = 'EXTPWSUSER';

  DELETE FROM parties WHERE par_org_name like 'Jim and James Group%';
  DELETE FROM parties WHERE par_org_name like 'Marks & Spencer%';

 
  -- Insert the system notices test cases
  INSERT INTO system_notices
   ( syno_title, syno_system,
     syno_start_date, syno_start_time, syno_end_date, syno_end_time, 
     syno_completed_ind, syno_frv_sat_code, syno_wrk_refno, 
     syno_more_information_url)
  VALUES
   ('Portal- This is a test notice', 'PWS',
     TO_DATE('11-OCT-2021','DD-MON-YYYY HH24:MI:SS'), '06:00', TO_DATE('10-OCT-3021','DD-MON-YYYY HH24:MI:SS'), '00:00',
     'N', 'PORTAL', 1, 'https://www.google.com/');
										
  INSERT INTO system_notices
   ( syno_title, syno_system,
     syno_start_date, syno_start_time, syno_end_date, syno_end_time, 
     syno_completed_ind, syno_frv_sat_code, syno_wrk_refno, 
     syno_more_information_url)
  VALUES
   ('LBTT Lease Review - This is a test notice with a full stop and a space. ', 'PWS',
     TO_DATE('11-OCT-2021','DD-MON-YYYY HH24:MI:SS'), '06:00', NULL, NULL,
     'N', 'LBTTREVIEW', 1, 'https://www.google.com/');

  INSERT INTO system_notices
   ( syno_title, syno_system,
     syno_start_date, syno_start_time, syno_end_date, syno_end_time, 
     syno_completed_ind, syno_frv_sat_code, syno_wrk_refno, 
     syno_more_information_url)
  VALUES
   ('SLFT application - This is a test notice with a full stop.', 'PWS',
     TO_DATE('11-OCT-2021','DD-MON-YYYY HH24:MI:SS'), '06:00', NULL, NULL,
     'N', 'SLFTFORMS', 1, 'https://www.google.com/');

  INSERT INTO system_notices
   ( syno_title, syno_system,
     syno_start_date, syno_start_time, syno_end_date, syno_end_time, 
     syno_completed_ind, syno_frv_sat_code, syno_wrk_refno, 
     syno_more_information_url)
  VALUES
   ('Repayment Request - This is a test notice without a URL', 'PWS',
     TO_DATE('11-OCT-2021','DD-MON-YYYY HH24:MI:SS'), '06:00', NULL, NULL,
     'N', 'REPAYMENT', 1, NULL);

  INSERT INTO system_notices
   ( syno_title, syno_system,
     syno_start_date, syno_start_time, syno_end_date, syno_end_time, 
     syno_completed_ind, syno_frv_sat_code, syno_wrk_refno, 
     syno_more_information_url)
  VALUES
   ('All - This is a test notice', 'PWS',
     TO_DATE('11-OCT-2021','DD-MON-YYYY HH24:MI:SS'), '06:00', NULL, NULL,
     'N', 'ALL', 1, 'https://www.google.com/');

  INSERT INTO system_notices
   ( syno_title, syno_system,
     syno_start_date, syno_start_time, syno_end_date, syno_end_time, 
     syno_completed_ind, syno_frv_sat_code, syno_wrk_refno, 
     syno_more_information_url)
  VALUES
   ('All - This is a test notice with complete indicator is Y', 'PWS',
     TO_DATE('11-OCT-2021','DD-MON-YYYY HH24:MI:SS'), '06:00', NULL, NULL,
     'Y', 'ALL', 1, 'https://www.google.com/');

  INSERT INTO system_notices
   ( syno_title, syno_system,
     syno_start_date, syno_start_time, syno_end_date, syno_end_time, 
     syno_completed_ind, syno_frv_sat_code, syno_wrk_refno, 
     syno_more_information_url)
  VALUES
   ('All - This is a test notice with expired date', 'PWS',
     TO_DATE('11-OCT-2021','DD-MON-YYYY HH24:MI:SS'), '06:00', TO_DATE('12-OCT-2021','DD-MON-YYYY HH24:MI:SS'), '23:59',
     'Y', 'ALL', 1, 'https://www.google.com/');
     
  -- Create the Main account
  INSERT INTO parties
    (par_refno,par_type,par_com_company_name,par_org_name,par_marketing_ind,par_fact_type,par_fact_frd_domain,par_fact_srv_code,par_fact_wrk_refno)
  VALUES
    (par_refno_seq.nextval,'ORG','Test Portal Company','Test Portal Company','N','AGENT','PARTY_ACT_TYPES','SYS',1)
  RETURNING par_refno INTO l_par_refno;

-- contact details are recorded against the user not the party on registration
--  create_or_maintain_cde(p_par_refno=>l_par_refno,p_cde_cme_code=>'USERNAME',p_value=>p_username);     
  create_or_maintain_cde(p_par_refno=>l_par_refno,p_cde_cme_code=>'EMAIL',p_value=>'noreply@necsws.com');
  create_or_maintain_cde(p_par_refno=>l_par_refno,p_cde_cme_code=>'PHONE',p_value=>'07700900321');
  create_or_maintain_address(p_refno=>l_par_refno,p_fao_code=>'PAR',p_adr_address_line_1=>'1 Acacia Avenue',p_adr_address_line_2=>'Garden Village',p_adr_town=>'NORTHTOWN',p_adr_county=>'Northshire',p_adr_postcode=>'RG1 1PB');
       
      
  -- Note password is created by hashing the username and the password
  INSERT INTO users
     (usr_username,usr_password,usr_password_change_date,usr_force_pw_change,usr_current_ind,usr_name,usr_email_address,usr_wrk_refno,
      usr_int_user_ind,usr_par_refno,usr_per_title, usr_per_forename,usr_per_surname,usr_pref_nld_code,usr_tac_signed_date)
  VALUES
     ('PORTAL.ONE',UPPER (dbms_obfuscation_toolkit.md5 (input => utl_i18n.string_to_raw('PORTAL.ONE'||'Password1!'))),TRUNC(SYSDATE),'N','Y','Portal User One','noreply@necsws.com',3,
      'N',l_par_Refno,'MR','Portal User','One','ENG',TRUNC(SYSDATE));
      
  INSERT INTO role_users
    (rus_rol_code,rus_usr_username)
  (SELECT rus_rol_code,'PORTAL.ONE'
    FROM role_users
   WHERE rus_usr_username = 'TEMPLATE_SELFSRV_USER');
   
   INSERT INTO user_services
    (use_username, use_service)
   VALUES
    ('PORTAL.ONE','LBTT');
           
  INSERT INTO users
     (usr_username,usr_password,usr_password_change_date,usr_force_pw_change,usr_current_ind,usr_name,usr_email_address,usr_wrk_refno,
      usr_int_user_ind,usr_par_refno,usr_per_forename,usr_per_surname,usr_pref_nld_code,usr_tac_signed_date)
  VALUES
     ('PORTAL.TWO',UPPER (dbms_obfuscation_toolkit.md5 (input => utl_i18n.string_to_raw('PORTAL.TWO'||'Password2!'))),TRUNC(SYSDATE),'N','Y','User One','noreply@necsws.com',3,
      'N',l_par_Refno,'Portal User','Two','ENG',TRUNC(SYSDATE));
      
  INSERT INTO role_users
    (rus_rol_code,rus_usr_username)
  (SELECT rus_rol_code,'PORTAL.TWO'
    FROM role_users
   WHERE rus_usr_username = 'TEMPLATE_SELFSRV_USER');
   
   INSERT INTO user_services
    (use_username, use_service)
   VALUES
    ('PORTAL.TWO','LBTT');  

    INSERT INTO parties
    (par_refno,par_type,par_per_surname,par_per_forename,par_marketing_ind,par_fact_type,par_fact_frd_domain,par_fact_srv_code,par_fact_wrk_refno)
  VALUES
    (par_refno_seq.nextval,'PER','Portal-Test','Adam','N','TAXPAYER','PARTY_ACT_TYPES','SYS',1)
  RETURNING par_refno INTO l_par_refno_new;
  
  create_or_maintain_cde(p_par_refno=>l_par_refno,p_cde_cme_code=>'EMAIL',p_value=>'noreply@necsws.com');
  create_or_maintain_cde(p_par_refno=>l_par_refno,p_cde_cme_code=>'PHONE',p_value=>'07700900321');
  create_or_maintain_address(p_refno=>l_par_refno,p_fao_code=>'PAR',p_adr_address_line_1=>'3 Park Lane',p_adr_address_line_2=>'Garden Village',p_adr_town=>'NORTHTOWN',p_adr_county=>'Northshire',p_adr_postcode=>'RG1 1PB');
  
  
  
  INSERT INTO users
     (usr_username,usr_password,usr_password_change_date,usr_force_pw_change,usr_current_ind,usr_name,usr_email_address,usr_wrk_refno,
      usr_int_user_ind,usr_par_refno,usr_per_forename,usr_per_surname,usr_pref_nld_code,usr_tac_signed_date)
  VALUES
     ('PORTAL.THREE',UPPER (dbms_obfuscation_toolkit.md5 (input => utl_i18n.string_to_raw('PORTAL.THREE'||'Password3!'))),
     TRUNC(SYSDATE),'N','Y','User Three','noreply@necsws.com',3,
      'N',l_par_refno_new,'Portal User','Three','ENG',TRUNC(SYSDATE));
      
  INSERT INTO role_users
    (rus_rol_code,rus_usr_username)
  (SELECT rus_rol_code,'PORTAL.THREE'
    FROM role_users
   WHERE rus_usr_username = 'TEMPLATE_SELFSRV_USER');
   
   INSERT INTO user_services
    (use_username, use_service)
   VALUES
    ('PORTAL.THREE','LBTT');


  INSERT INTO users
     (usr_username,usr_password,usr_password_change_date,usr_force_pw_change,usr_current_ind,usr_name,usr_email_address,usr_wrk_refno,
      usr_int_user_ind,usr_par_refno,usr_per_forename,usr_per_surname,usr_pref_nld_code,usr_tac_signed_date)
  VALUES
     ('PORTAL.NON.CURRENT',UPPER (dbms_obfuscation_toolkit.md5 (input => utl_i18n.string_to_raw('PORTAL.NON.CURRENT'||'Password3!'))),TRUNC(SYSDATE),'N','N','Portal Non Current','noreply@necsws.com',3,
      'N',l_par_Refno,'Portal User','Non Current','ENG',TRUNC(SYSDATE));
      
  INSERT INTO role_users
    (rus_rol_code,rus_usr_username)
  (SELECT rus_rol_code,'PORTAL.NON.CURRENT'
    FROM role_users
   WHERE rus_usr_username = 'TEMPLATE_SELFSRV_USER');
   
   INSERT INTO user_services
    (use_username, use_service)
   VALUES
    ('PORTAL.NON.CURRENT','LBTT');   

  INSERT INTO users
     (usr_username,usr_password,usr_password_change_date,usr_force_pw_change,usr_current_ind,usr_name,usr_email_address,usr_wrk_refno,
      usr_int_user_ind,usr_par_refno,usr_per_forename,usr_per_surname,usr_pref_nld_code,usr_tac_signed_date)
  VALUES
     ('PORTAL.CHANGE@DETAILS',UPPER (dbms_obfuscation_toolkit.md5 (input => utl_i18n.string_to_raw('PORTAL.CHANGE@DETAILS'||'Password3!'))),TRUNC(SYSDATE),'N','N','Portal Change Details','noreply@necsws.com',3,
      'N',l_par_Refno,'Portal User','Change Details','ENG',TRUNC(SYSDATE));
      
  INSERT INTO role_users
    (rus_rol_code,rus_usr_username)
  (SELECT rus_rol_code,'PORTAL.CHANGE@DETAILS'
    FROM role_users
   WHERE rus_usr_username = 'TEMPLATE_SELFSRV_USER');
   
   INSERT INTO user_services
    (use_username, use_service)
   VALUES
    ('PORTAL.CHANGE@DETAILS','LBTT');

   -- User that has no access except dashboard
  INSERT INTO users
     (usr_username,usr_password,usr_password_change_date,usr_force_pw_change,usr_current_ind,usr_name,usr_email_address,usr_wrk_refno,
      usr_int_user_ind,usr_par_refno,usr_per_forename,usr_per_surname,usr_pref_nld_code,usr_tac_signed_date)
  VALUES
     ('PORTAL.NO.ACCESS',UPPER (dbms_obfuscation_toolkit.md5 (input => utl_i18n.string_to_raw('PORTAL.NO.ACCESS'||'Password1!'))),TRUNC(SYSDATE),'N','Y','Portal No Access','noreply@necsws.com',3,
      'N',l_par_Refno,'Portal User','No Access','ENG',TRUNC(SYSDATE));
      
  INSERT INTO role_users
    (rus_rol_code,rus_usr_username)
  (SELECT rus_rol_code,'PORTAL.NO.ACCESS'
    FROM role_users
   WHERE rus_usr_username = 'TEMPLATE_SELFSRV_USER'
     AND rus_rol_code IN ('PWSDASH'));

   INSERT INTO user_services
    (use_username, use_service)
   VALUES
    ('PORTAL.NO.ACCESS','LBTT');


    
  --*********************************
  -- Create the LBTT returns for the PORTAL.ONE account
  --*********************************
  -- Draft and Final

  fl_variables.set_g_username('PORTAL.ONE');
  
  INSERT INTO tax_returns
   (tare_refno, tare_reference, tare_srv_code)
  VALUES
   (tare_seq.nextval,'RS2000001AAAA','LBTT')
  returning tare_refno INTO l_tare_refno;

-- Final version
  INSERT INTO lbtt_returns (
    lbtt_tare_refno,lbtt_version,lbtt_source,lbtt_latest_draft_ind,lbtt_agent_reference,
    lbtt_fpty_type,lbtt_fpty_frd_domain,lbtt_fpty_srv_code,lbtt_fpty_wrk_refno,
    lbtt_flbt_type,lbtt_flbt_frd_domain,lbtt_flbt_srv_code,lbtt_flbt_wrk_refno,
    lbtt_effective_date,lbtt_submitted_date,lbtt_relevant_date,lbtt_contract_date,
    lbtt_business_ind,lbtt_moveables_ind,lbtt_stock_ind,lbtt_goodwill_ind,lbtt_other_ind,
    lbtt_non_chargeable,lbtt_total_vat,lbtt_remaining_chargeable,
    lbtt_exchange_ind,lbtt_uk_ind,lbtt_linked_ind,lbtt_previous_option_ind,
    lbtt_linked_consideration,lbtt_total_consideration,
    lbtt_calculated,lbtt_due_before_reliefs,lbtt_total_reliefs,lbtt_tax_due,
    lbtt_orig_calculated,lbtt_orig_due_before_reliefs,lbtt_orig_total_reliefs,lbtt_orig_tax_due,
    lbtt_ads_due_ind,lbtt_ads_due,lbtt_orig_ads_due,
    lbtt_fpay_method,lbtt_fpay_frd_domain,lbtt_fpay_srv_code,lbtt_fpay_wrk_refno,lbtt_sche_code,lbtt_scve_version_id
) VALUES (
    l_tare_refno,1,'P','L','HS/XXX/TH/CO99999.0001',
    '1','PROPERTYTYPE','SYS',1, -- Residential
    'CONVEY','RETURN TYPE','LBTT',1,
    AMENDABLE_DATE,AMENDABLE_DATE,AMENDABLE_DATE,AMENDABLE_DATE,
    'N','N','N','N','N',
    0,0,100000,
    'N','N','N','N',
    0,100000,
    1000,1000,0,1000,
    1000,1000,0,1000,
    'N',0,0,
    'BACS','PAYMENT TYPE','LBTT',1,'LBTT_RATE', 0);
    
  INSERT INTO properties (
    pro_lau_code,pro_lau_frd_domain,pro_lau_wrk_refno, pro_lau_srv_code
  ) VALUES (
    '9055','LAU',1, 'SYS'
  ) returning pro_refno INTO l_pro_refno;
  
   create_or_maintain_address(p_refno=>l_pro_refno,p_fao_code=>'PRO',p_adr_address_line_1=>'1 Peabody Avenue',
     p_adr_address_line_2=>'',p_adr_town=>'Hemel Hempstead',p_adr_county=>'Hertfordshire',p_adr_postcode=>'HP2 7DX',p_adr_type=>'PHYSICAL');
 
   history_tables_api.snapshot_property( p_pro_refno=>l_pro_refno,p_snapshot_src_vn=>NULL,p_proh_version=>l_h_version);
                             
  INSERT INTO lbtt_properties (
    lppr_pro_refno,lppr_lbtt_tare_refno,lppr_lbtt_version,lppr_proh_version
  ) VALUES (
    l_pro_refno,l_tare_refno,1,l_h_version);

  INSERT INTO properties (
    pro_lau_code,pro_lau_frd_domain,pro_lau_wrk_refno, pro_lau_srv_code
  ) VALUES (
    '9055','LAU',1, 'SYS'
  ) returning pro_refno INTO l_pro_refno;
  
   create_or_maintain_address(p_refno=>l_pro_refno,p_fao_code=>'PRO',p_adr_address_line_1=>'2 Peabody Avenue',
     p_adr_address_line_2=>'',p_adr_town=>'Hemel Hempstead',p_adr_county=>'Hertfordshire',p_adr_postcode=>'HP2 7DX',p_adr_type=>'PHYSICAL');
 
   history_tables_api.snapshot_property( p_pro_refno=>l_pro_refno,p_snapshot_src_vn=>NULL,p_proh_version=>l_h_version);
 
  INSERT INTO lbtt_properties (
    lppr_pro_refno,lppr_lbtt_tare_refno,lppr_lbtt_version,lppr_proh_version
  ) VALUES (
    l_pro_refno,l_tare_refno,1,l_h_version);
    

  INSERT INTO parties
    (par_refno,par_type,par_per_surname,par_per_forename,par_marketing_ind)
  VALUES
    (par_refno_seq.nextval,'PER','Buyer-First','Adam','N')
  RETURNING par_refno INTO l_tmp_par_refno;
  
  create_or_maintain_address(p_refno=>l_tmp_par_refno,p_fao_code=>'PAR',p_adr_address_line_1=>'11 Park Lane',
    p_adr_address_line_2=>'Garden Village',p_adr_town=>'NORTHTOWN',p_adr_county=>'Northshire',p_adr_postcode=>'RG1 1PB');

  history_tables_api.snapshot_party( p_par_refno=>l_tmp_par_refno,p_snapshot_src_vn=>NULL,p_parh_version=>l_h_version);

  INSERT INTO lbtt_return_party_links (
    lpli_par_refno,lpli_lbtt_tare_refno,lpli_lbtt_version,
    lpli_flpt_type,lpli_flpt_srv_code,lpli_flpt_frd_domain,lpli_flpt_wrk_refno,
    lpli_buyer_seller_linked_ind,lpli_authority_ind,lpli_orig_authority_ind,lpli_parh_version
) VALUES (
    l_tmp_par_refno,l_tare_refno,1,
    'BUYER','LBTT','RETURNPARTYLINKS',1,
    'N','N','N',l_h_version);
    
   INSERT INTO parties
    (par_refno,par_type,par_per_surname,par_per_forename,par_marketing_ind)
   VALUES
    (par_refno_seq.nextval,'PER','Buyer-Second','Bert','N')
   RETURNING par_refno INTO l_tmp_par_refno;
  
  create_or_maintain_address(p_refno=>l_tmp_par_refno,p_fao_code=>'PAR',p_adr_address_line_1=>'12 Park Lane',
    p_adr_address_line_2=>'Garden Village',p_adr_town=>'NORTHTOWN',p_adr_county=>'Northshire',p_adr_postcode=>'RG1 1PB');

  history_tables_api.snapshot_party( p_par_refno=>l_tmp_par_refno,p_snapshot_src_vn=>NULL,p_parh_version=>l_h_version);

  INSERT INTO lbtt_return_party_links (
    lpli_par_refno,lpli_lbtt_tare_refno,lpli_lbtt_version,
    lpli_flpt_type,lpli_flpt_srv_code,lpli_flpt_frd_domain,lpli_flpt_wrk_refno,
    lpli_buyer_seller_linked_ind,lpli_authority_ind,lpli_orig_authority_ind,lpli_parh_version
) VALUES (
    l_tmp_par_refno,l_tare_refno,1,
    'BUYER','LBTT','RETURNPARTYLINKS',1,
    'N','N','N',l_h_version);
    
   INSERT INTO parties
    (par_refno,par_type,par_per_surname,par_per_forename,par_marketing_ind)
   VALUES
    (par_refno_seq.nextval,'PER','Seller-Second','Charles','N')
   RETURNING par_refno INTO l_tmp_par_refno;
  
  create_or_maintain_address(p_refno=>l_tmp_par_refno,p_fao_code=>'PAR',p_adr_address_line_1=>'11 Tree Rd',
    p_adr_address_line_2=>'Garden Village',p_adr_town=>'NORTHTOWN',p_adr_county=>'Northshire',p_adr_postcode=>'RG1 1PB');

  history_tables_api.snapshot_party( p_par_refno=>l_tmp_par_refno,p_snapshot_src_vn=>NULL,p_parh_version=>l_h_version);
    
  INSERT INTO lbtt_return_party_links (
    lpli_par_refno,lpli_lbtt_tare_refno,lpli_lbtt_version,
    lpli_flpt_type,lpli_flpt_srv_code,lpli_flpt_frd_domain,lpli_flpt_wrk_refno,
    lpli_buyer_seller_linked_ind,lpli_authority_ind,lpli_orig_authority_ind,lpli_parh_version
) VALUES (
    l_tmp_par_refno,l_tare_refno,1,
    'SELLER','LBTT','RETURNPARTYLINKS',1,
    'N','N','N',l_h_version); 
    
    -- Insert the agent and the link to the account
    history_tables_api.snapshot_party( p_par_refno=>l_par_refno,p_snapshot_src_vn=>NULL,p_parh_version=>l_h_version);

    INSERT INTO lbtt_return_party_links (
    lpli_par_refno,lpli_lbtt_tare_refno,lpli_lbtt_version,
    lpli_flpt_type,lpli_flpt_srv_code,lpli_flpt_frd_domain,lpli_flpt_wrk_refno,
    lpli_buyer_seller_linked_ind,lpli_authority_ind,lpli_orig_authority_ind,lpli_parh_version
   ) VALUES (
    l_par_refno,l_tare_refno,1,
    'AGENT','LBTT','RETURNPARTYLINKS',1,
    'Y','N','N',l_h_version);

   -- Draft version
  INSERT INTO lbtt_returns (
    lbtt_tare_refno,lbtt_version,lbtt_source,lbtt_latest_draft_ind,lbtt_agent_reference,
    lbtt_fpty_type,lbtt_fpty_frd_domain,lbtt_fpty_srv_code,lbtt_fpty_wrk_refno,
    lbtt_flbt_type,lbtt_flbt_frd_domain,lbtt_flbt_srv_code,lbtt_flbt_wrk_refno,
    lbtt_effective_date,lbtt_submitted_date,lbtt_relevant_date,lbtt_contract_date,
    lbtt_business_ind,lbtt_moveables_ind,lbtt_stock_ind,lbtt_goodwill_ind,lbtt_other_ind,
    lbtt_non_chargeable,lbtt_total_vat,lbtt_remaining_chargeable,
    lbtt_exchange_ind,lbtt_uk_ind,lbtt_linked_ind,lbtt_previous_option_ind,
    lbtt_linked_consideration,lbtt_total_consideration,
    lbtt_calculated,lbtt_due_before_reliefs,lbtt_total_reliefs,lbtt_tax_due,
    lbtt_orig_calculated,lbtt_orig_due_before_reliefs,lbtt_orig_total_reliefs,lbtt_orig_tax_due,
    lbtt_ads_due_ind,lbtt_ads_due,lbtt_orig_ads_due,
    lbtt_fpay_method,lbtt_fpay_frd_domain,lbtt_fpay_srv_code,lbtt_fpay_wrk_refno,lbtt_sche_code,lbtt_scve_version_id
) VALUES (
    l_tare_refno,2,'P','D','AAAA BB DDDDFFFF 9999.2',
    '1','PROPERTYTYPE','SYS',1, -- Residential
    'CONVEY','RETURN TYPE','LBTT',1,
    AMENDABLE_DATE,NULL,AMENDABLE_DATE,AMENDABLE_DATE,
    'N','N','N','N','N',
    0,0,100000,
    'N','N','N','N',
    0,100000,
    1000,1000,0,1000,
    1000,1000,0,1000,
    'N',0,0,
    'BACS','PAYMENT TYPE','LBTT',1,'LBTT_RATE', 0);
    
  INSERT INTO properties (
    pro_lau_code,pro_lau_frd_domain,pro_lau_wrk_refno, pro_lau_srv_code
  ) VALUES (
    '9055','LAU',1, 'SYS'
  ) returning pro_refno INTO l_pro_refno;
  
   create_or_maintain_address(p_refno=>l_pro_refno,p_fao_code=>'PRO',p_adr_address_line_1=>'1 Peabody Avenue',
     p_adr_address_line_2=>'',p_adr_town=>'Hemel Hempstead',p_adr_county=>'Hertfordshire',p_adr_postcode=>'HP2 7DX',p_adr_type=>'PHYSICAL');
 
   history_tables_api.snapshot_property( p_pro_refno=>l_pro_refno,p_snapshot_src_vn=>NULL,p_proh_version=>l_h_version);
                             
  INSERT INTO lbtt_properties (
    lppr_pro_refno,lppr_lbtt_tare_refno,lppr_lbtt_version,lppr_proh_version
  ) VALUES (
    l_pro_refno,l_tare_refno,2,l_h_version);

  INSERT INTO properties (
    pro_lau_code,pro_lau_frd_domain,pro_lau_wrk_refno, pro_lau_srv_code
  ) VALUES (
    '9055','LAU',1, 'SYS'
  ) returning pro_refno INTO l_pro_refno;
  
   create_or_maintain_address(p_refno=>l_pro_refno,p_fao_code=>'PRO',p_adr_address_line_1=>'2 Peabody Avenue',
     p_adr_address_line_2=>'',p_adr_town=>'Hemel Hempstead',p_adr_county=>'Hertfordshire',p_adr_postcode=>'HP2 7DX',p_adr_type=>'PHYSICAL');
 
   history_tables_api.snapshot_property( p_pro_refno=>l_pro_refno,p_snapshot_src_vn=>NULL,p_proh_version=>l_h_version);
 
  INSERT INTO lbtt_properties (
    lppr_pro_refno,lppr_lbtt_tare_refno,lppr_lbtt_version,lppr_proh_version
  ) VALUES (
    l_pro_refno,l_tare_refno,2,l_h_version);
    

  INSERT INTO parties
    (par_refno,par_type,par_per_surname,par_per_forename,par_marketing_ind)
  VALUES
    (par_refno_seq.nextval,'PER','Buyer-First','Adam','N')
  RETURNING par_refno INTO l_tmp_par_refno;
  
  create_or_maintain_address(p_refno=>l_tmp_par_refno,p_fao_code=>'PAR',p_adr_address_line_1=>'11 Park Lane',
    p_adr_address_line_2=>'Garden Village',p_adr_town=>'NORTHTOWN',p_adr_county=>'Northshire',p_adr_postcode=>'RG1 1PB');

  history_tables_api.snapshot_party( p_par_refno=>l_tmp_par_refno,p_snapshot_src_vn=>NULL,p_parh_version=>l_h_version);

  INSERT INTO lbtt_return_party_links (
    lpli_par_refno,lpli_lbtt_tare_refno,lpli_lbtt_version,
    lpli_flpt_type,lpli_flpt_srv_code,lpli_flpt_frd_domain,lpli_flpt_wrk_refno,
    lpli_buyer_seller_linked_ind,lpli_authority_ind,lpli_orig_authority_ind,lpli_parh_version
) VALUES (
    l_tmp_par_refno,l_tare_refno,2,
    'BUYER','LBTT','RETURNPARTYLINKS',1,
    'N','N','N',l_h_version);
    
   INSERT INTO parties
    (par_refno,par_type,par_per_surname,par_per_forename,par_marketing_ind)
   VALUES
    (par_refno_seq.nextval,'PER','Buyer-Second','Bert','N')
   RETURNING par_refno INTO l_tmp_par_refno;
  
  create_or_maintain_address(p_refno=>l_tmp_par_refno,p_fao_code=>'PAR',p_adr_address_line_1=>'12 Park Lane',
    p_adr_address_line_2=>'Garden Village',p_adr_town=>'NORTHTOWN',p_adr_county=>'Northshire',p_adr_postcode=>'RG1 1PB');

  history_tables_api.snapshot_party( p_par_refno=>l_tmp_par_refno,p_snapshot_src_vn=>NULL,p_parh_version=>l_h_version);

  INSERT INTO lbtt_return_party_links (
    lpli_par_refno,lpli_lbtt_tare_refno,lpli_lbtt_version,
    lpli_flpt_type,lpli_flpt_srv_code,lpli_flpt_frd_domain,lpli_flpt_wrk_refno,
    lpli_buyer_seller_linked_ind,lpli_authority_ind,lpli_orig_authority_ind,lpli_parh_version
) VALUES (
    l_tmp_par_refno,l_tare_refno,2,
    'BUYER','LBTT','RETURNPARTYLINKS',1,
    'N','N','N',l_h_version);
    
   INSERT INTO parties
    (par_refno,par_type,par_per_surname,par_per_forename,par_marketing_ind)
   VALUES
    (par_refno_seq.nextval,'PER','Seller-Second','Charles','N')
   RETURNING par_refno INTO l_tmp_par_refno;
  
  create_or_maintain_address(p_refno=>l_tmp_par_refno,p_fao_code=>'PAR',p_adr_address_line_1=>'11 Tree Rd',
    p_adr_address_line_2=>'Garden Village',p_adr_town=>'NORTHTOWN',p_adr_county=>'Northshire',p_adr_postcode=>'RG1 1PB');

  history_tables_api.snapshot_party( p_par_refno=>l_tmp_par_refno,p_snapshot_src_vn=>NULL,p_parh_version=>l_h_version);
    
  INSERT INTO lbtt_return_party_links (
    lpli_par_refno,lpli_lbtt_tare_refno,lpli_lbtt_version,
    lpli_flpt_type,lpli_flpt_srv_code,lpli_flpt_frd_domain,lpli_flpt_wrk_refno,
    lpli_buyer_seller_linked_ind,lpli_authority_ind,lpli_orig_authority_ind,lpli_parh_version
) VALUES (
    l_tmp_par_refno,l_tare_refno,2,
    'SELLER','LBTT','RETURNPARTYLINKS',1,
    'N','N','N',l_h_version); 
    
    -- Insert the agent and the link to the account
    history_tables_api.snapshot_party( p_par_refno=>l_par_refno,p_snapshot_src_vn=>NULL,p_parh_version=>l_h_version);

    INSERT INTO lbtt_return_party_links (
    lpli_par_refno,lpli_lbtt_tare_refno,lpli_lbtt_version,
    lpli_flpt_type,lpli_flpt_srv_code,lpli_flpt_frd_domain,lpli_flpt_wrk_refno,
    lpli_buyer_seller_linked_ind,lpli_authority_ind,lpli_orig_authority_ind,lpli_parh_version
   ) VALUES (
    l_par_refno,l_tare_refno,2,
    'AGENT','LBTT','RETURNPARTYLINKS',1,
    'Y','N','N',l_h_version);

  fl_variables.set_g_username('PORTAL.TWO');

  update lbtt_returns
  set lbtt_modified_by = 'PORTAL.TWO'
  where lbtt_tare_refno = l_tare_refno;

  fl_variables.set_g_username('EXTPWSUSER');  

  -- FINAL conveyance with ADS
  INSERT INTO tax_returns
   (tare_refno, tare_reference, tare_srv_code)
  VALUES
   (tare_seq.nextval,'RS2000001SSSS','LBTT')
  returning tare_refno INTO l_tare_refno;

-- Final version
  INSERT INTO lbtt_returns (
    lbtt_tare_refno,lbtt_version,lbtt_source,lbtt_latest_draft_ind,lbtt_agent_reference,
    lbtt_fpty_type,lbtt_fpty_frd_domain,lbtt_fpty_srv_code,lbtt_fpty_wrk_refno,
    lbtt_flbt_type,lbtt_flbt_frd_domain,lbtt_flbt_srv_code,lbtt_flbt_wrk_refno,
    lbtt_effective_date,lbtt_submitted_date,lbtt_relevant_date,lbtt_contract_date,
    lbtt_business_ind,lbtt_moveables_ind,lbtt_stock_ind,lbtt_goodwill_ind,lbtt_other_ind,
    lbtt_non_chargeable,lbtt_total_vat,lbtt_remaining_chargeable,
    lbtt_exchange_ind,lbtt_uk_ind,lbtt_linked_ind,lbtt_previous_option_ind,
    lbtt_linked_consideration,lbtt_total_consideration,
    lbtt_calculated,lbtt_due_before_reliefs,lbtt_total_reliefs,lbtt_tax_due,
    lbtt_orig_calculated,lbtt_orig_due_before_reliefs,lbtt_orig_total_reliefs,lbtt_orig_tax_due,
    lbtt_ads_due_ind,lbtt_ads_due,lbtt_orig_ads_due,
    lbtt_fpay_method,lbtt_fpay_frd_domain,lbtt_fpay_srv_code,lbtt_fpay_wrk_refno,lbtt_sche_code,lbtt_scve_version_id,
    lbtt_ads_sell_residence_ind,lbtt_ads_amount_liable
) VALUES (
    l_tare_refno,1,'P','L','AaBbCc',
    '1','PROPERTYTYPE','SYS',1, -- Residential
    'CONVEY','RETURN TYPE','LBTT',1,
    AMENDABLE_DATE,AMENDABLE_DATE,AMENDABLE_DATE,AMENDABLE_DATE,
    'N','N','N','N','N',
    0,0,100000,
    'N','N','N','N',
    0,100000,
    1000,1000,0,1000,
    1000,1000,0,1000,
    'Y',0,0,
    'BACS','PAYMENT TYPE','LBTT',1,'LBTT_RATE', 0,
    'N', 1000);
    
  INSERT INTO properties (
    pro_lau_code,pro_lau_frd_domain,pro_lau_wrk_refno, pro_lau_srv_code
  ) VALUES (
    '9055','LAU',1, 'SYS'
  ) returning pro_refno INTO l_pro_refno;
  
   create_or_maintain_address(p_refno=>l_pro_refno,p_fao_code=>'PRO',p_adr_address_line_1=>'1 Peabody Avenue',
     p_adr_address_line_2=>'',p_adr_town=>'Hemel Hempstead',p_adr_county=>'Hertfordshire',p_adr_postcode=>'HP2 7DX',p_adr_type=>'PHYSICAL');
 
   history_tables_api.snapshot_property( p_pro_refno=>l_pro_refno,p_snapshot_src_vn=>NULL,p_proh_version=>l_h_version);
                             
  INSERT INTO lbtt_properties (
    lppr_pro_refno,lppr_lbtt_tare_refno,lppr_lbtt_version,lppr_proh_version, lppr_ads_due_ind
  ) VALUES (
    l_pro_refno,l_tare_refno,1,l_h_version, 'Y');    

  INSERT INTO parties
    (par_refno,par_type,par_per_surname,par_per_forename,par_marketing_ind)
  VALUES
    (par_refno_seq.nextval,'PER','Buyer-First','Harry','N')
  RETURNING par_refno INTO l_tmp_par_refno;
  
  create_or_maintain_address(p_refno=>l_tmp_par_refno,p_fao_code=>'PAR',p_adr_address_line_1=>'11 Park Lane',
    p_adr_address_line_2=>'Garden Village',p_adr_town=>'NORTHTOWN',p_adr_county=>'Northshire',p_adr_postcode=>'RG1 1PB');

  history_tables_api.snapshot_party( p_par_refno=>l_tmp_par_refno,p_snapshot_src_vn=>NULL,p_parh_version=>l_h_version);

  INSERT INTO lbtt_return_party_links (
    lpli_par_refno,lpli_lbtt_tare_refno,lpli_lbtt_version,
    lpli_flpt_type,lpli_flpt_srv_code,lpli_flpt_frd_domain,lpli_flpt_wrk_refno,
    lpli_buyer_seller_linked_ind,lpli_authority_ind,lpli_orig_authority_ind,lpli_parh_version
) VALUES (
    l_tmp_par_refno,l_tare_refno,1,
    'BUYER','LBTT','RETURNPARTYLINKS',1,
    'N','N','N',l_h_version);
    
   INSERT INTO parties
    (par_refno,par_type,par_per_surname,par_per_forename,par_marketing_ind)
   VALUES
    (par_refno_seq.nextval,'PER','Seller-Second','Charles','N')
   RETURNING par_refno INTO l_tmp_par_refno;
  
  create_or_maintain_address(p_refno=>l_tmp_par_refno,p_fao_code=>'PAR',p_adr_address_line_1=>'11 Tree Rd',
    p_adr_address_line_2=>'Garden Village',p_adr_town=>'NORTHTOWN',p_adr_county=>'Northshire',p_adr_postcode=>'RG1 1PB');

  history_tables_api.snapshot_party( p_par_refno=>l_tmp_par_refno,p_snapshot_src_vn=>NULL,p_parh_version=>l_h_version);
    
  INSERT INTO lbtt_return_party_links (
    lpli_par_refno,lpli_lbtt_tare_refno,lpli_lbtt_version,
    lpli_flpt_type,lpli_flpt_srv_code,lpli_flpt_frd_domain,lpli_flpt_wrk_refno,
    lpli_buyer_seller_linked_ind,lpli_authority_ind,lpli_orig_authority_ind,lpli_parh_version
) VALUES (
    l_tmp_par_refno,l_tare_refno,1,
    'SELLER','LBTT','RETURNPARTYLINKS',1,
    'N','N','N',l_h_version); 
    
    -- Insert the agent and the link to the account
    history_tables_api.snapshot_party( p_par_refno=>l_par_refno,p_snapshot_src_vn=>NULL,p_parh_version=>l_h_version);

    INSERT INTO lbtt_return_party_links (
    lpli_par_refno,lpli_lbtt_tare_refno,lpli_lbtt_version,
    lpli_flpt_type,lpli_flpt_srv_code,lpli_flpt_frd_domain,lpli_flpt_wrk_refno,
    lpli_buyer_seller_linked_ind,lpli_authority_ind,lpli_orig_authority_ind,lpli_parh_version
   ) VALUES (
    l_par_refno,l_tare_refno,1,
    'AGENT','LBTT','RETURNPARTYLINKS',1,
    'Y','N','N',l_h_version);

  fl_variables.set_g_username('EXTPWSUSER'); 

  -- FINAL conveyance with ADS
  INSERT INTO tax_returns
   (tare_refno, tare_reference, tare_srv_code)
  VALUES
   (tare_seq.nextval,'RS2000001HHHH','LBTT')
  returning tare_refno INTO l_tare_refno;

-- Final version
  INSERT INTO lbtt_returns (
    lbtt_tare_refno,lbtt_version,lbtt_source,lbtt_latest_draft_ind,lbtt_agent_reference,
    lbtt_fpty_type,lbtt_fpty_frd_domain,lbtt_fpty_srv_code,lbtt_fpty_wrk_refno,
    lbtt_flbt_type,lbtt_flbt_frd_domain,lbtt_flbt_srv_code,lbtt_flbt_wrk_refno,
    lbtt_effective_date,lbtt_submitted_date,lbtt_relevant_date,lbtt_contract_date,
    lbtt_business_ind,lbtt_moveables_ind,lbtt_stock_ind,lbtt_goodwill_ind,lbtt_other_ind,
    lbtt_non_chargeable,lbtt_total_vat,lbtt_remaining_chargeable,
    lbtt_exchange_ind,lbtt_uk_ind,lbtt_linked_ind,lbtt_previous_option_ind,
    lbtt_linked_consideration,lbtt_total_consideration,
    lbtt_calculated,lbtt_due_before_reliefs,lbtt_total_reliefs,lbtt_tax_due,
    lbtt_orig_calculated,lbtt_orig_due_before_reliefs,lbtt_orig_total_reliefs,lbtt_orig_tax_due,
    lbtt_ads_due_ind,lbtt_ads_due,lbtt_orig_ads_due,
    lbtt_fpay_method,lbtt_fpay_frd_domain,lbtt_fpay_srv_code,lbtt_fpay_wrk_refno,lbtt_sche_code,lbtt_scve_version_id,
    lbtt_ads_sell_residence_ind,lbtt_ads_amount_liable
) VALUES (
    l_tare_refno,1,'P','D','AaBbCc',
    '1','PROPERTYTYPE','SYS',1, -- Residential
    'CONVEY','RETURN TYPE','LBTT',1,
    AMENDABLE_DATE,AMENDABLE_DATE,AMENDABLE_DATE,AMENDABLE_DATE,
    'N','N','N','N','N',
    0,0,110000,
    'N','N','N','N',
    0,100000,
    1000,1000,0,1000,
    1000,1000,0,1000,
    'Y',0,0,
    'BACS','PAYMENT TYPE','LBTT',1,'LBTT_RATE', 2,
    'N', 1000);
    
  INSERT INTO properties (
    pro_lau_code,pro_lau_frd_domain,pro_lau_wrk_refno, pro_lau_srv_code
  ) VALUES (
    '9055','LAU',1, 'SYS'
  ) returning pro_refno INTO l_pro_refno;
  
   create_or_maintain_address(p_refno=>l_pro_refno,p_fao_code=>'PRO',p_adr_address_line_1=>'1 Peabody Avenue',
     p_adr_address_line_2=>'',p_adr_town=>'Hemel Hempstead',p_adr_county=>'Hertfordshire',p_adr_postcode=>'HP2 7DX',p_adr_type=>'PHYSICAL');
 
   history_tables_api.snapshot_property( p_pro_refno=>l_pro_refno,p_snapshot_src_vn=>NULL,p_proh_version=>l_h_version);
                             
  INSERT INTO lbtt_properties (
    lppr_pro_refno,lppr_lbtt_tare_refno,lppr_lbtt_version,lppr_proh_version, lppr_ads_due_ind
  ) VALUES (
    l_pro_refno,l_tare_refno,1,l_h_version, 'Y');    

  INSERT INTO parties
    (par_refno,par_type,par_per_surname,par_per_forename,par_marketing_ind, PAR_PER_NI_NO)
  VALUES
    (par_refno_seq.nextval,'PER','Buyer-First','Jason','N', 'AA123456B')
  RETURNING par_refno INTO l_tmp_par_refno;
  
  create_or_maintain_cde(p_par_refno=>l_tmp_par_refno,p_cde_cme_code=>'EMAIL',p_value=>'noreply@necsws.com');
  create_or_maintain_cde(p_par_refno=>l_tmp_par_refno,p_cde_cme_code=>'PHONE',p_value=>'07700900321');
  create_or_maintain_address(p_refno=>l_tmp_par_refno,p_fao_code=>'PAR',p_adr_address_line_1=>'11 Park Lane',
    p_adr_address_line_2=>'Garden Village',p_adr_town=>'NORTHTOWN',p_adr_county=>'Northshire',p_adr_postcode=>'RG1 1PB');

  history_tables_api.snapshot_party( p_par_refno=>l_tmp_par_refno,p_snapshot_src_vn=>NULL,p_parh_version=>l_h_version);

  INSERT INTO lbtt_return_party_links (
    lpli_par_refno,lpli_lbtt_tare_refno,lpli_lbtt_version,
    lpli_flpt_type,lpli_flpt_srv_code,lpli_flpt_frd_domain,lpli_flpt_wrk_refno,
    lpli_buyer_seller_linked_ind,lpli_authority_ind,lpli_orig_authority_ind,lpli_parh_version
) VALUES (
    l_tmp_par_refno,l_tare_refno,1,
    'BUYER','LBTT','RETURNPARTYLINKS',1,
    'N','N','N',l_h_version);
    
   INSERT INTO parties
    (par_refno,par_type,par_per_surname,par_per_forename,par_marketing_ind)
   VALUES
    (par_refno_seq.nextval,'PER','Seller-Second','Micheal','N')
   RETURNING par_refno INTO l_tmp_par_refno;
  
  create_or_maintain_address(p_refno=>l_tmp_par_refno,p_fao_code=>'PAR',p_adr_address_line_1=>'11 Tree Rd',
    p_adr_address_line_2=>'Garden Village',p_adr_town=>'NORTHTOWN',p_adr_county=>'Northshire',p_adr_postcode=>'RG1 1PB');

  history_tables_api.snapshot_party( p_par_refno=>l_tmp_par_refno,p_snapshot_src_vn=>NULL,p_parh_version=>l_h_version);
    
  INSERT INTO lbtt_return_party_links (
    lpli_par_refno,lpli_lbtt_tare_refno,lpli_lbtt_version,
    lpli_flpt_type,lpli_flpt_srv_code,lpli_flpt_frd_domain,lpli_flpt_wrk_refno,
    lpli_buyer_seller_linked_ind,lpli_authority_ind,lpli_orig_authority_ind,lpli_parh_version
) VALUES (
    l_tmp_par_refno,l_tare_refno,1,
    'SELLER','LBTT','RETURNPARTYLINKS',1,
    'N','N','N',l_h_version); 
    
    -- Insert the agent and the link to the account
    history_tables_api.snapshot_party( p_par_refno=>l_par_refno,p_snapshot_src_vn=>NULL,p_parh_version=>l_h_version);

    INSERT INTO lbtt_return_party_links (
    lpli_par_refno,lpli_lbtt_tare_refno,lpli_lbtt_version,
    lpli_flpt_type,lpli_flpt_srv_code,lpli_flpt_frd_domain,lpli_flpt_wrk_refno,
    lpli_buyer_seller_linked_ind,lpli_authority_ind,lpli_orig_authority_ind,lpli_parh_version
   ) VALUES (
    l_par_refno,l_tare_refno,1,
    'AGENT','LBTT','RETURNPARTYLINKS',1,
    'Y','N','N',l_h_version);

  --------
  -- FINAL conveyance more thant 12 months with no ADS claim
  INSERT INTO tax_returns
   (tare_refno, tare_reference, tare_srv_code)
  VALUES
   (tare_seq.nextval,'RS2000002AAAA','LBTT')
  returning tare_refno INTO l_tare_refno;
  
  --- Insert the main ads address
  INSERT INTO addresses
     (adr_refno,adr_address_line_1,adr_address_line_2,adr_town,adr_postcode,adr_county,adr_country)
  VALUES
     (adr_seq.nextval,'12 Market Street',NULL,'Northtown','NP7 8LB',NULL,'GB')
  RETURNING adr_refno INTO l_adr_refno;

  INSERT INTO lbtt_returns (
    lbtt_tare_refno,lbtt_version,lbtt_source,lbtt_latest_draft_ind,lbtt_agent_reference,
    lbtt_fpty_type,lbtt_fpty_frd_domain,lbtt_fpty_srv_code,lbtt_fpty_wrk_refno,
    lbtt_flbt_type,lbtt_flbt_frd_domain,lbtt_flbt_srv_code,lbtt_flbt_wrk_refno,
    lbtt_effective_date,lbtt_submitted_date,lbtt_relevant_date,lbtt_contract_date,
    lbtt_business_ind,lbtt_moveables_ind,lbtt_stock_ind,lbtt_goodwill_ind,lbtt_other_ind,
    lbtt_non_chargeable,lbtt_total_vat,lbtt_remaining_chargeable,
    lbtt_exchange_ind,lbtt_uk_ind,lbtt_linked_ind,lbtt_previous_option_ind,
    lbtt_linked_consideration,lbtt_total_consideration,
    lbtt_calculated,lbtt_due_before_reliefs,lbtt_total_reliefs,lbtt_tax_due,
    lbtt_orig_calculated,lbtt_orig_due_before_reliefs,lbtt_orig_total_reliefs,lbtt_orig_tax_due,
    lbtt_ads_due_ind,lbtt_ads_due,lbtt_orig_ads_due,lbtt_ads_main_adr_refno,
    lbtt_fpay_method,lbtt_fpay_frd_domain,lbtt_fpay_srv_code,lbtt_fpay_wrk_refno
) VALUES (
    l_tare_refno,1,'P','L','ABcC',
    '1','PROPERTYTYPE','SYS',1, -- Residential
    'CONVEY','RETURN TYPE','LBTT',1,
    '01-JUL-2017','01-JUL-2017','01-JUL-2017','01-JUL-2017',
    'N','N','N','N','N',
    0,0,100000,
    'N','N','N','N',
    0,100000,
    1000,1000,0,1000,
    1000,1000,0,1000,
    'Y',100,100,l_adr_refno,
    'BACS','PAYMENT TYPE','LBTT',1);
    
  INSERT INTO properties (
    pro_lau_code,pro_lau_frd_domain,pro_lau_wrk_refno, pro_lau_srv_code
  ) VALUES (
    '9055','LAU',1, 'SYS'
  ) returning pro_refno INTO l_pro_refno;
  
   create_or_maintain_address(p_refno=>l_pro_refno,p_fao_code=>'PRO',p_adr_address_line_1=>'10 Peabody Avenue',
     p_adr_address_line_2=>'',p_adr_town=>'Hemel Hempstead',p_adr_county=>'Hertfordshire',p_adr_postcode=>'HP2 7DX',p_adr_type=>'PHYSICAL');
 
   history_tables_api.snapshot_property( p_pro_refno=>l_pro_refno,p_snapshot_src_vn=>NULL,p_proh_version=>l_h_version);
                             
  INSERT INTO lbtt_properties (
    lppr_pro_refno,lppr_lbtt_tare_refno,lppr_lbtt_version,lppr_proh_version,lppr_ads_due_ind
  ) VALUES (
    l_pro_refno,l_tare_refno,1,l_h_version,'Y');

  INSERT INTO parties
    (par_refno,par_type,par_per_surname,par_per_forename,par_marketing_ind)
  VALUES
    (par_refno_seq.nextval,'PER','Buyer-First','Charles','N')
  RETURNING par_refno INTO l_tmp_par_refno;
  
  create_or_maintain_address(p_refno=>l_tmp_par_refno,p_fao_code=>'PAR',p_adr_address_line_1=>'21 Park Lane',
    p_adr_address_line_2=>'Garden Village',p_adr_town=>'NORTHTOWN',p_adr_county=>'Northshire',p_adr_postcode=>'RG1 1PB');

  history_tables_api.snapshot_party( p_par_refno=>l_tmp_par_refno,p_snapshot_src_vn=>NULL,p_parh_version=>l_h_version);

  INSERT INTO lbtt_return_party_links (
    lpli_par_refno,lpli_lbtt_tare_refno,lpli_lbtt_version,
    lpli_flpt_type,lpli_flpt_srv_code,lpli_flpt_frd_domain,lpli_flpt_wrk_refno,
    lpli_buyer_seller_linked_ind,lpli_authority_ind,lpli_orig_authority_ind,lpli_parh_version
) VALUES (
    l_tmp_par_refno,l_tare_refno,1,
    'BUYER','LBTT','RETURNPARTYLINKS',1,
    'N','N','N',l_h_version);
   
   INSERT INTO parties
    (par_refno,par_type,par_per_surname,par_per_forename,par_marketing_ind)
   VALUES
    (par_refno_seq.nextval,'PER','Seller-First','Doris','N')
   RETURNING par_refno INTO l_tmp_par_refno;
  
  create_or_maintain_address(p_refno=>l_tmp_par_refno,p_fao_code=>'PAR',p_adr_address_line_1=>'21 Tree Rd',
    p_adr_address_line_2=>'Garden Village',p_adr_town=>'NORTHTOWN',p_adr_county=>'Northshire',p_adr_postcode=>'RG1 1PB');

  history_tables_api.snapshot_party( p_par_refno=>l_tmp_par_refno,p_snapshot_src_vn=>NULL,p_parh_version=>l_h_version);
    
  INSERT INTO lbtt_return_party_links (
    lpli_par_refno,lpli_lbtt_tare_refno,lpli_lbtt_version,
    lpli_flpt_type,lpli_flpt_srv_code,lpli_flpt_frd_domain,lpli_flpt_wrk_refno,
    lpli_buyer_seller_linked_ind,lpli_authority_ind,lpli_orig_authority_ind,lpli_parh_version
) VALUES (
    l_tmp_par_refno,l_tare_refno,1,
    'SELLER','LBTT','RETURNPARTYLINKS',1,
    'N','N','N',l_h_version); 
    
    -- Insert the agent and the link to the account
    history_tables_api.snapshot_party( p_par_refno=>l_par_refno,p_snapshot_src_vn=>NULL,p_parh_version=>l_h_version);

    INSERT INTO lbtt_return_party_links (
    lpli_par_refno,lpli_lbtt_tare_refno,lpli_lbtt_version,
    lpli_flpt_type,lpli_flpt_srv_code,lpli_flpt_frd_domain,lpli_flpt_wrk_refno,
    lpli_buyer_seller_linked_ind,lpli_authority_ind,lpli_orig_authority_ind,lpli_parh_version
   ) VALUES (
    l_par_refno,l_tare_refno,1,
    'AGENT','LBTT','RETURNPARTYLINKS',1,
    'Y','N','N',l_h_version);
	
  --------
  -- FINAL conveyance less thant 12 months with no ADS claim and five buyers
  INSERT INTO tax_returns
   (tare_refno, tare_reference, tare_srv_code)
  VALUES
   (tare_seq.nextval,'RS2000004DDDD','LBTT')
  returning tare_refno INTO l_tare_refno;
  
  --- Insert the main ads address
  INSERT INTO addresses
     (adr_refno,adr_address_line_1,adr_address_line_2,adr_town,adr_postcode,adr_county,adr_country)
  VALUES
     (adr_seq.nextval,'14 Cattle Street',NULL,'Northtown','NP7 8LB',NULL,'GB')
  RETURNING adr_refno INTO l_adr_refno;

  INSERT INTO lbtt_returns (
    lbtt_tare_refno,lbtt_version,lbtt_source,lbtt_latest_draft_ind,lbtt_agent_reference,
    lbtt_fpty_type,lbtt_fpty_frd_domain,lbtt_fpty_srv_code,lbtt_fpty_wrk_refno,
    lbtt_flbt_type,lbtt_flbt_frd_domain,lbtt_flbt_srv_code,lbtt_flbt_wrk_refno,
    lbtt_effective_date,lbtt_submitted_date,lbtt_relevant_date,lbtt_contract_date,
    lbtt_business_ind,lbtt_moveables_ind,lbtt_stock_ind,lbtt_goodwill_ind,lbtt_other_ind,
    lbtt_non_chargeable,lbtt_total_vat,lbtt_remaining_chargeable,
    lbtt_exchange_ind,lbtt_uk_ind,lbtt_linked_ind,lbtt_previous_option_ind,
    lbtt_linked_consideration,lbtt_total_consideration,
    lbtt_calculated,lbtt_due_before_reliefs,lbtt_total_reliefs,lbtt_tax_due,
    lbtt_orig_calculated,lbtt_orig_due_before_reliefs,lbtt_orig_total_reliefs,lbtt_orig_tax_due,
    lbtt_ads_due_ind,lbtt_ads_due,lbtt_orig_ads_due,lbtt_ads_main_adr_refno,
    lbtt_fpay_method,lbtt_fpay_frd_domain,lbtt_fpay_srv_code,lbtt_fpay_wrk_refno
) VALUES (
    l_tare_refno,1,'P','L','ABcC',
    '1','PROPERTYTYPE','SYS',1, -- Residential
    'CONVEY','RETURN TYPE','LBTT',1,
    AMENDABLE_DATE,AMENDABLE_DATE,AMENDABLE_DATE,AMENDABLE_DATE,
    'N','N','N','N','N',
    0,0,100000,
    'N','N','N','N',
    0,100000,
    1000,1000,0,1000,
    1000,1000,0,1000,
    'Y',100,100,l_adr_refno,
    'BACS','PAYMENT TYPE','LBTT',1);
    
  INSERT INTO properties (
    pro_lau_code,pro_lau_frd_domain,pro_lau_wrk_refno, pro_lau_srv_code
  ) VALUES (
    '9055','LAU',1, 'SYS'
  ) returning pro_refno INTO l_pro_refno;
  
   create_or_maintain_address(p_refno=>l_pro_refno,p_fao_code=>'PRO',p_adr_address_line_1=>'14 Cucumber Avenue',
     p_adr_address_line_2=>'',p_adr_town=>'Hemel Hempstead',p_adr_county=>'Hertfordshire',p_adr_postcode=>'HP2 7DX',p_adr_type=>'PHYSICAL');
 
   history_tables_api.snapshot_property( p_pro_refno=>l_pro_refno,p_snapshot_src_vn=>NULL,p_proh_version=>l_h_version);
                             
  INSERT INTO lbtt_properties (
    lppr_pro_refno,lppr_lbtt_tare_refno,lppr_lbtt_version,lppr_proh_version,lppr_ads_due_ind
  ) VALUES (
    l_pro_refno,l_tare_refno,1,l_h_version,'Y');

  INSERT INTO parties
    (par_refno,par_type,par_per_surname,par_per_forename,par_marketing_ind)
  VALUES
    (par_refno_seq.nextval,'PER','Buyer-First','Daniel','N')
  RETURNING par_refno INTO l_tmp_par_refno;
  
  create_or_maintain_address(p_refno=>l_tmp_par_refno,p_fao_code=>'PAR',p_adr_address_line_1=>'24 Playground Lane',
    p_adr_address_line_2=>'Garden Village',p_adr_town=>'NORTHTOWN',p_adr_county=>'Northshire',p_adr_postcode=>'RG1 1PB');

  history_tables_api.snapshot_party( p_par_refno=>l_tmp_par_refno,p_snapshot_src_vn=>NULL,p_parh_version=>l_h_version);

  INSERT INTO lbtt_return_party_links (
    lpli_par_refno,lpli_lbtt_tare_refno,lpli_lbtt_version,
    lpli_flpt_type,lpli_flpt_srv_code,lpli_flpt_frd_domain,lpli_flpt_wrk_refno,
    lpli_buyer_seller_linked_ind,lpli_authority_ind,lpli_orig_authority_ind,lpli_parh_version
) VALUES (
    l_tmp_par_refno,l_tare_refno,1,
    'BUYER','LBTT','RETURNPARTYLINKS',1,
    'N','N','N',l_h_version);
    
  INSERT INTO parties
    (par_refno,par_type,par_per_surname,par_per_forename,par_marketing_ind)
  VALUES
    (par_refno_seq.nextval,'PER','Buyer-Second','Francis','N')
  RETURNING par_refno INTO l_tmp_par_refno;
  
  create_or_maintain_address(p_refno=>l_tmp_par_refno,p_fao_code=>'PAR',p_adr_address_line_1=>'24 Playground Lane',
    p_adr_address_line_2=>'Garden Village',p_adr_town=>'NORTHTOWN',p_adr_county=>'Northshire',p_adr_postcode=>'RG1 1PB');

  history_tables_api.snapshot_party( p_par_refno=>l_tmp_par_refno,p_snapshot_src_vn=>NULL,p_parh_version=>l_h_version);

  INSERT INTO lbtt_return_party_links (
    lpli_par_refno,lpli_lbtt_tare_refno,lpli_lbtt_version,
    lpli_flpt_type,lpli_flpt_srv_code,lpli_flpt_frd_domain,lpli_flpt_wrk_refno,
    lpli_buyer_seller_linked_ind,lpli_authority_ind,lpli_orig_authority_ind,lpli_parh_version
) VALUES (
    l_tmp_par_refno,l_tare_refno,1,
    'BUYER','LBTT','RETURNPARTYLINKS',1,
    'N','N','N',l_h_version);

  INSERT INTO parties
    (par_refno,par_type,par_per_surname,par_per_forename,par_marketing_ind)
  VALUES
    (par_refno_seq.nextval,'PER','Buyer-Third','Graham','N')
  RETURNING par_refno INTO l_tmp_par_refno;
  
  create_or_maintain_address(p_refno=>l_tmp_par_refno,p_fao_code=>'PAR',p_adr_address_line_1=>'26 Playground Lane',
    p_adr_address_line_2=>'Garden Village',p_adr_town=>'NORTHTOWN',p_adr_county=>'Northshire',p_adr_postcode=>'RG1 1PB');

  history_tables_api.snapshot_party( p_par_refno=>l_tmp_par_refno,p_snapshot_src_vn=>NULL,p_parh_version=>l_h_version);

  INSERT INTO lbtt_return_party_links (
    lpli_par_refno,lpli_lbtt_tare_refno,lpli_lbtt_version,
    lpli_flpt_type,lpli_flpt_srv_code,lpli_flpt_frd_domain,lpli_flpt_wrk_refno,
    lpli_buyer_seller_linked_ind,lpli_authority_ind,lpli_orig_authority_ind,lpli_parh_version
) VALUES (
    l_tmp_par_refno,l_tare_refno,1,
    'BUYER','LBTT','RETURNPARTYLINKS',1,
    'N','N','N',l_h_version);
   
  INSERT INTO parties
    (par_refno,par_type,par_per_surname,par_per_forename,par_marketing_ind)
  VALUES
    (par_refno_seq.nextval,'PER','Buyer-Fourth','Helen','N')
  RETURNING par_refno INTO l_tmp_par_refno;
  
  create_or_maintain_address(p_refno=>l_tmp_par_refno,p_fao_code=>'PAR',p_adr_address_line_1=>'28 Playground Lane',
    p_adr_address_line_2=>'Garden Village',p_adr_town=>'NORTHTOWN',p_adr_county=>'Northshire',p_adr_postcode=>'RG1 1PB');

  history_tables_api.snapshot_party( p_par_refno=>l_tmp_par_refno,p_snapshot_src_vn=>NULL,p_parh_version=>l_h_version);

  INSERT INTO lbtt_return_party_links (
    lpli_par_refno,lpli_lbtt_tare_refno,lpli_lbtt_version,
    lpli_flpt_type,lpli_flpt_srv_code,lpli_flpt_frd_domain,lpli_flpt_wrk_refno,
    lpli_buyer_seller_linked_ind,lpli_authority_ind,lpli_orig_authority_ind,lpli_parh_version
) VALUES (
    l_tmp_par_refno,l_tare_refno,1,
    'BUYER','LBTT','RETURNPARTYLINKS',1,
    'N','N','N',l_h_version);
   
  INSERT INTO parties
    (par_refno,par_type,par_per_surname,par_per_forename,par_marketing_ind)
  VALUES
    (par_refno_seq.nextval,'PER','Buyer-Fifth','Ian','N')
  RETURNING par_refno INTO l_tmp_par_refno;
  
  create_or_maintain_address(p_refno=>l_tmp_par_refno,p_fao_code=>'PAR',p_adr_address_line_1=>'30 Playground Lane',
    p_adr_address_line_2=>'Garden Village',p_adr_town=>'NORTHTOWN',p_adr_county=>'Northshire',p_adr_postcode=>'RG1 1PB');

  history_tables_api.snapshot_party( p_par_refno=>l_tmp_par_refno,p_snapshot_src_vn=>NULL,p_parh_version=>l_h_version);

  INSERT INTO lbtt_return_party_links (
    lpli_par_refno,lpli_lbtt_tare_refno,lpli_lbtt_version,
    lpli_flpt_type,lpli_flpt_srv_code,lpli_flpt_frd_domain,lpli_flpt_wrk_refno,
    lpli_buyer_seller_linked_ind,lpli_authority_ind,lpli_orig_authority_ind,lpli_parh_version
) VALUES (
    l_tmp_par_refno,l_tare_refno,1,
    'BUYER','LBTT','RETURNPARTYLINKS',1,
    'N','N','N',l_h_version);
   
   INSERT INTO parties
    (par_refno,par_type,par_per_surname,par_per_forename,par_marketing_ind)
   VALUES
    (par_refno_seq.nextval,'PER','Seller-First','Edna','N')
   RETURNING par_refno INTO l_tmp_par_refno;
  
  create_or_maintain_address(p_refno=>l_tmp_par_refno,p_fao_code=>'PAR',p_adr_address_line_1=>'25 Cedar Rd',
    p_adr_address_line_2=>'Garden Village',p_adr_town=>'NORTHTOWN',p_adr_county=>'Northshire',p_adr_postcode=>'RG1 1PB');

  history_tables_api.snapshot_party( p_par_refno=>l_tmp_par_refno,p_snapshot_src_vn=>NULL,p_parh_version=>l_h_version);
    
  INSERT INTO lbtt_return_party_links (
    lpli_par_refno,lpli_lbtt_tare_refno,lpli_lbtt_version,
    lpli_flpt_type,lpli_flpt_srv_code,lpli_flpt_frd_domain,lpli_flpt_wrk_refno,
    lpli_buyer_seller_linked_ind,lpli_authority_ind,lpli_orig_authority_ind,lpli_parh_version
) VALUES (
    l_tmp_par_refno,l_tare_refno,1,
    'SELLER','LBTT','RETURNPARTYLINKS',1,
    'N','N','N',l_h_version); 
    
    -- Insert the agent and the link to the account
    history_tables_api.snapshot_party( p_par_refno=>l_par_refno,p_snapshot_src_vn=>NULL,p_parh_version=>l_h_version);

    INSERT INTO lbtt_return_party_links (
    lpli_par_refno,lpli_lbtt_tare_refno,lpli_lbtt_version,
    lpli_flpt_type,lpli_flpt_srv_code,lpli_flpt_frd_domain,lpli_flpt_wrk_refno,
    lpli_buyer_seller_linked_ind,lpli_authority_ind,lpli_orig_authority_ind,lpli_parh_version
   ) VALUES (
    l_par_refno,l_tare_refno,1,
    'AGENT','LBTT','RETURNPARTYLINKS',1,
    'Y','N','N',l_h_version);

  --------
  -- FINAL conveyance more thant 12 months with open ADS claim and five buyers
  INSERT INTO tax_returns
   (tare_refno, tare_reference, tare_srv_code)
  VALUES
   (tare_seq.nextval,'RS3000002AAAA','LBTT')
  returning tare_refno INTO l_tare_refno;
  
  --- Insert the main ads address
  INSERT INTO addresses
     (adr_refno,adr_address_line_1,adr_address_line_2,adr_town,adr_postcode,adr_county,adr_country)
  VALUES
     (adr_seq.nextval,'32 Market Street',NULL,'Northtown','NP7 8LB',NULL,'GB')
  RETURNING adr_refno INTO l_adr_refno;

  INSERT INTO lbtt_returns (
    lbtt_tare_refno,lbtt_version,lbtt_source,lbtt_latest_draft_ind,lbtt_agent_reference,
    lbtt_fpty_type,lbtt_fpty_frd_domain,lbtt_fpty_srv_code,lbtt_fpty_wrk_refno,
    lbtt_flbt_type,lbtt_flbt_frd_domain,lbtt_flbt_srv_code,lbtt_flbt_wrk_refno,
    lbtt_effective_date,lbtt_submitted_date,lbtt_relevant_date,lbtt_contract_date,
    lbtt_business_ind,lbtt_moveables_ind,lbtt_stock_ind,lbtt_goodwill_ind,lbtt_other_ind,
    lbtt_non_chargeable,lbtt_total_vat,lbtt_remaining_chargeable,
    lbtt_exchange_ind,lbtt_uk_ind,lbtt_linked_ind,lbtt_previous_option_ind,
    lbtt_linked_consideration,lbtt_total_consideration,
    lbtt_calculated,lbtt_due_before_reliefs,lbtt_total_reliefs,lbtt_tax_due,
    lbtt_orig_calculated,lbtt_orig_due_before_reliefs,lbtt_orig_total_reliefs,lbtt_orig_tax_due,
    lbtt_ads_due_ind,lbtt_ads_due,lbtt_orig_ads_due,lbtt_ads_main_adr_refno,
    lbtt_fpay_method,lbtt_fpay_frd_domain,lbtt_fpay_srv_code,lbtt_fpay_wrk_refno
) VALUES (
    l_tare_refno,1,'P','L','ABcC',
    '1','PROPERTYTYPE','SYS',1, -- Residential
    'CONVEY','RETURN TYPE','LBTT',1,
    '01-JUL-2017','01-JUL-2017','01-JUL-2017','01-JUL-2017',
    'N','N','N','N','N',
    0,0,100000,
    'N','N','N','N',
    0,100000,
    1000,1000,0,1000,
    1000,1000,0,1000,
    'Y',100,100,l_adr_refno,
    'BACS','PAYMENT TYPE','LBTT',1);
    
  INSERT INTO properties (
    pro_lau_code,pro_lau_frd_domain,pro_lau_wrk_refno, pro_lau_srv_code
  ) VALUES (
    '9055','LAU',1, 'SYS'
  ) returning pro_refno INTO l_pro_refno;
  
   create_or_maintain_address(p_refno=>l_pro_refno,p_fao_code=>'PRO',p_adr_address_line_1=>'30 Peabody Avenue',
     p_adr_address_line_2=>'',p_adr_town=>'Hemel Hempstead',p_adr_county=>'Hertfordshire',p_adr_postcode=>'HP2 7DX',p_adr_type=>'PHYSICAL');
 
   history_tables_api.snapshot_property( p_pro_refno=>l_pro_refno,p_snapshot_src_vn=>NULL,p_proh_version=>l_h_version);
                             
  INSERT INTO lbtt_properties (
    lppr_pro_refno,lppr_lbtt_tare_refno,lppr_lbtt_version,lppr_proh_version,lppr_ads_due_ind
  ) VALUES (
    l_pro_refno,l_tare_refno,1,l_h_version,'Y');

  INSERT INTO parties
    (par_refno,par_type,par_per_surname,par_per_forename,par_marketing_ind)
  VALUES
    (par_refno_seq.nextval,'PER','Buyer-First','George','N')
  RETURNING par_refno INTO l_tmp_par_refno;
  
  create_or_maintain_address(p_refno=>l_tmp_par_refno,p_fao_code=>'PAR',p_adr_address_line_1=>'31 Park Lane',
    p_adr_address_line_2=>'Garden Village',p_adr_town=>'NORTHTOWN',p_adr_county=>'Northshire',p_adr_postcode=>'RG1 1PB');

  history_tables_api.snapshot_party( p_par_refno=>l_tmp_par_refno,p_snapshot_src_vn=>NULL,p_parh_version=>l_h_version);

  INSERT INTO lbtt_return_party_links (
    lpli_par_refno,lpli_lbtt_tare_refno,lpli_lbtt_version,
    lpli_flpt_type,lpli_flpt_srv_code,lpli_flpt_frd_domain,lpli_flpt_wrk_refno,
    lpli_buyer_seller_linked_ind,lpli_authority_ind,lpli_orig_authority_ind,lpli_parh_version
) VALUES (
    l_tmp_par_refno,l_tare_refno,1,
    'BUYER','LBTT','RETURNPARTYLINKS',1,
    'N','N','N',l_h_version);

  INSERT INTO parties
    (par_refno,par_type,par_per_surname,par_per_forename,par_marketing_ind)
  VALUES
    (par_refno_seq.nextval,'PER','Buyer-Second','Harold','N')
  RETURNING par_refno INTO l_tmp_par_refno;
  
  create_or_maintain_address(p_refno=>l_tmp_par_refno,p_fao_code=>'PAR',p_adr_address_line_1=>'32 Park Lane',
    p_adr_address_line_2=>'Garden Village',p_adr_town=>'NORTHTOWN',p_adr_county=>'Northshire',p_adr_postcode=>'RG1 1PB');

  history_tables_api.snapshot_party( p_par_refno=>l_tmp_par_refno,p_snapshot_src_vn=>NULL,p_parh_version=>l_h_version);

  INSERT INTO lbtt_return_party_links (
    lpli_par_refno,lpli_lbtt_tare_refno,lpli_lbtt_version,
    lpli_flpt_type,lpli_flpt_srv_code,lpli_flpt_frd_domain,lpli_flpt_wrk_refno,
    lpli_buyer_seller_linked_ind,lpli_authority_ind,lpli_orig_authority_ind,lpli_parh_version
) VALUES (
    l_tmp_par_refno,l_tare_refno,1,
    'BUYER','LBTT','RETURNPARTYLINKS',1,
    'N','N','N',l_h_version);

  INSERT INTO parties
    (par_refno,par_type,par_per_surname,par_per_forename,par_marketing_ind)
  VALUES
    (par_refno_seq.nextval,'PER','Buyer-Third','Ian','N')
  RETURNING par_refno INTO l_tmp_par_refno;
  
  create_or_maintain_address(p_refno=>l_tmp_par_refno,p_fao_code=>'PAR',p_adr_address_line_1=>'33 Park Lane',
    p_adr_address_line_2=>'Garden Village',p_adr_town=>'NORTHTOWN',p_adr_county=>'Northshire',p_adr_postcode=>'RG1 1PB');

  history_tables_api.snapshot_party( p_par_refno=>l_tmp_par_refno,p_snapshot_src_vn=>NULL,p_parh_version=>l_h_version);

  INSERT INTO lbtt_return_party_links (
    lpli_par_refno,lpli_lbtt_tare_refno,lpli_lbtt_version,
    lpli_flpt_type,lpli_flpt_srv_code,lpli_flpt_frd_domain,lpli_flpt_wrk_refno,
    lpli_buyer_seller_linked_ind,lpli_authority_ind,lpli_orig_authority_ind,lpli_parh_version
) VALUES (
    l_tmp_par_refno,l_tare_refno,1,
    'BUYER','LBTT','RETURNPARTYLINKS',1,
    'N','N','N',l_h_version);
   
  INSERT INTO parties
    (par_refno,par_type,par_per_surname,par_per_forename,par_marketing_ind)
  VALUES
    (par_refno_seq.nextval,'PER','Buyer-Fourth','James','N')
  RETURNING par_refno INTO l_tmp_par_refno;
  
  create_or_maintain_address(p_refno=>l_tmp_par_refno,p_fao_code=>'PAR',p_adr_address_line_1=>'35 Park Lane',
    p_adr_address_line_2=>'Garden Village',p_adr_town=>'NORTHTOWN',p_adr_county=>'Northshire',p_adr_postcode=>'RG1 1PB');

  history_tables_api.snapshot_party( p_par_refno=>l_tmp_par_refno,p_snapshot_src_vn=>NULL,p_parh_version=>l_h_version);

  INSERT INTO lbtt_return_party_links (
    lpli_par_refno,lpli_lbtt_tare_refno,lpli_lbtt_version,
    lpli_flpt_type,lpli_flpt_srv_code,lpli_flpt_frd_domain,lpli_flpt_wrk_refno,
    lpli_buyer_seller_linked_ind,lpli_authority_ind,lpli_orig_authority_ind,lpli_parh_version
) VALUES (
    l_tmp_par_refno,l_tare_refno,1,
    'BUYER','LBTT','RETURNPARTYLINKS',1,
    'N','N','N',l_h_version);
   
  INSERT INTO parties
    (par_refno,par_type,par_per_surname,par_per_forename,par_marketing_ind)
  VALUES
    (par_refno_seq.nextval,'PER','Buyer-Fifth','Keith','N')
  RETURNING par_refno INTO l_tmp_par_refno;
  
  create_or_maintain_address(p_refno=>l_tmp_par_refno,p_fao_code=>'PAR',p_adr_address_line_1=>'37 Park Lane',
    p_adr_address_line_2=>'Garden Village',p_adr_town=>'NORTHTOWN',p_adr_county=>'Northshire',p_adr_postcode=>'RG1 1PB');

  history_tables_api.snapshot_party( p_par_refno=>l_tmp_par_refno,p_snapshot_src_vn=>NULL,p_parh_version=>l_h_version);

  INSERT INTO lbtt_return_party_links (
    lpli_par_refno,lpli_lbtt_tare_refno,lpli_lbtt_version,
    lpli_flpt_type,lpli_flpt_srv_code,lpli_flpt_frd_domain,lpli_flpt_wrk_refno,
    lpli_buyer_seller_linked_ind,lpli_authority_ind,lpli_orig_authority_ind,lpli_parh_version
) VALUES (
    l_tmp_par_refno,l_tare_refno,1,
    'BUYER','LBTT','RETURNPARTYLINKS',1,
    'N','N','N',l_h_version);

   INSERT INTO parties
    (par_refno,par_type,par_per_surname,par_per_forename,par_marketing_ind)
   VALUES
    (par_refno_seq.nextval,'PER','Seller-First','Harriet','N')
   RETURNING par_refno INTO l_tmp_par_refno;
  
  create_or_maintain_address(p_refno=>l_tmp_par_refno,p_fao_code=>'PAR',p_adr_address_line_1=>'31 Tree Rd',
    p_adr_address_line_2=>'Garden Village',p_adr_town=>'NORTHTOWN',p_adr_county=>'Northshire',p_adr_postcode=>'RG1 1PB');

  history_tables_api.snapshot_party( p_par_refno=>l_tmp_par_refno,p_snapshot_src_vn=>NULL,p_parh_version=>l_h_version);
    
  INSERT INTO lbtt_return_party_links (
    lpli_par_refno,lpli_lbtt_tare_refno,lpli_lbtt_version,
    lpli_flpt_type,lpli_flpt_srv_code,lpli_flpt_frd_domain,lpli_flpt_wrk_refno,
    lpli_buyer_seller_linked_ind,lpli_authority_ind,lpli_orig_authority_ind,lpli_parh_version
) VALUES (
    l_tmp_par_refno,l_tare_refno,1,
    'SELLER','LBTT','RETURNPARTYLINKS',1,
    'N','N','N',l_h_version); 
    
    -- Insert the agent and the link to the account
    history_tables_api.snapshot_party( p_par_refno=>l_par_refno,p_snapshot_src_vn=>NULL,p_parh_version=>l_h_version);

    INSERT INTO lbtt_return_party_links (
    lpli_par_refno,lpli_lbtt_tare_refno,lpli_lbtt_version,
    lpli_flpt_type,lpli_flpt_srv_code,lpli_flpt_frd_domain,lpli_flpt_wrk_refno,
    lpli_buyer_seller_linked_ind,lpli_authority_ind,lpli_orig_authority_ind,lpli_parh_version
   ) VALUES (
    l_par_refno,l_tare_refno,1,
    'AGENT','LBTT','RETURNPARTYLINKS',1,
    'Y','N','N',l_h_version);
	
	
   -- Open repayment case	
  INSERT INTO cases (
    case_refno,case_reference,
    case_caty_type,case_caty_srv_code,case_caty_wrk_refno,
    case_cast_status,case_casr_reason,case_description,
    case_automatic_ind,case_fcas_source,case_fcas_frd_domain,case_fcas_wrk_refno,case_fcas_srv_code,
    case_receipt_date,case_all_information_date,
    case_fobt_type,case_fobt_frd_domain,case_fobt_wrk_refno,case_fobt_srv_code,case_related_reference
  ) VALUES (
    case_seq.nextval,'PORTAL.RS3000002AAAA',
    'ADS REPAYMENT','LBTT',1,
    'OPEN','ADS REPAYMENT TO PROCESS','Test Data',
    'Y','DASHBOARD','CASESOURCES',1,'LBTT',
    '01-SEP-2019','01-SEP-2019',
    'RETURN','OBJECT TYPES',1,'LBTT','RS3000002AAAA'
  )
  returning case_refno INTO l_case_refno;

   -- repayment request
  INSERT INTO return_repayments (
    rrep_refno,rrep_reference,rrep_type,rrep_tare_refno,rrep_version,
    rrep_par_refno,rrep_frer_reason,rrep_frer_frd_domain,rrep_frer_wrk_refno,rrep_frer_srv_code,
    rrep_case_refno,
    rrep_amount_claimed,rrep_account_holder,rrep_bank_account_no,rrep_bank_sort_code,rrep_bank_name,
    rrep_submitted_by,rrep_submitted_date,rrep_ads_family_ind
  ) VALUES (
    rrep_seq.nextval,'RS3000002AAAA','POST',l_tare_refno,1,
    l_par_refno,'ADS','CLAIMREASONS',1,'LBTT',
    l_case_refno,
    100,'Mickey Mouse','12345678','00-00-00','Floyds',
    user,'01-SEP-2019','N');
    
  --------
  -- FINAL conveyance less thant 12 months with an open ADS claim
  INSERT INTO tax_returns
   (tare_refno, tare_reference, tare_srv_code)
  VALUES
   (tare_seq.nextval,'RS3000004DDDD','LBTT')
  returning tare_refno INTO l_tare_refno;
  
  --- Insert the main ads address
  INSERT INTO addresses
     (adr_refno,adr_address_line_1,adr_address_line_2,adr_town,adr_postcode,adr_county,adr_country)
  VALUES
     (adr_seq.nextval,'34 Cattle Street',NULL,'Northtown','NP7 8LB',NULL,'GB')
  RETURNING adr_refno INTO l_adr_refno;

  INSERT INTO lbtt_returns (
    lbtt_tare_refno,lbtt_version,lbtt_source,lbtt_latest_draft_ind,lbtt_agent_reference,
    lbtt_fpty_type,lbtt_fpty_frd_domain,lbtt_fpty_srv_code,lbtt_fpty_wrk_refno,
    lbtt_flbt_type,lbtt_flbt_frd_domain,lbtt_flbt_srv_code,lbtt_flbt_wrk_refno,
    lbtt_effective_date,lbtt_submitted_date,lbtt_relevant_date,lbtt_contract_date,
    lbtt_business_ind,lbtt_moveables_ind,lbtt_stock_ind,lbtt_goodwill_ind,lbtt_other_ind,
    lbtt_non_chargeable,lbtt_total_vat,lbtt_remaining_chargeable,
    lbtt_exchange_ind,lbtt_uk_ind,lbtt_linked_ind,lbtt_previous_option_ind,
    lbtt_linked_consideration,lbtt_total_consideration,
    lbtt_calculated,lbtt_due_before_reliefs,lbtt_total_reliefs,lbtt_tax_due,
    lbtt_orig_calculated,lbtt_orig_due_before_reliefs,lbtt_orig_total_reliefs,lbtt_orig_tax_due,
    lbtt_ads_due_ind,lbtt_ads_due,lbtt_orig_ads_due,lbtt_ads_main_adr_refno,
    lbtt_fpay_method,lbtt_fpay_frd_domain,lbtt_fpay_srv_code,lbtt_fpay_wrk_refno
) VALUES (
    l_tare_refno,1,'P','L','ABcC',
    '1','PROPERTYTYPE','SYS',1, -- Residential
    'CONVEY','RETURN TYPE','LBTT',1,
    AMENDABLE_DATE,AMENDABLE_DATE,AMENDABLE_DATE,AMENDABLE_DATE,
    'N','N','N','N','N',
    0,0,100000,
    'N','N','N','N',
    0,100000,
    1000,1000,0,1000,
    1000,1000,0,1000,
    'Y',100,100,l_adr_refno,
    'BACS','PAYMENT TYPE','LBTT',1);
    
  INSERT INTO properties (
    pro_lau_code,pro_lau_frd_domain,pro_lau_wrk_refno, pro_lau_srv_code
  ) VALUES (
    '9055','LAU',1, 'SYS'
  ) returning pro_refno INTO l_pro_refno;
  
   create_or_maintain_address(p_refno=>l_pro_refno,p_fao_code=>'PRO',p_adr_address_line_1=>'34 Cucumber Avenue',
     p_adr_address_line_2=>'',p_adr_town=>'Hemel Hempstead',p_adr_county=>'Hertfordshire',p_adr_postcode=>'HP2 7DX',p_adr_type=>'PHYSICAL');
 
   history_tables_api.snapshot_property( p_pro_refno=>l_pro_refno,p_snapshot_src_vn=>NULL,p_proh_version=>l_h_version);
                             
  INSERT INTO lbtt_properties (
    lppr_pro_refno,lppr_lbtt_tare_refno,lppr_lbtt_version,lppr_proh_version,lppr_ads_due_ind
  ) VALUES (
    l_pro_refno,l_tare_refno,1,l_h_version,'Y');

  INSERT INTO parties
    (par_refno,par_type,par_per_surname,par_per_forename,par_marketing_ind)
  VALUES
    (par_refno_seq.nextval,'PER','Buyer-First','Ian','N')
  RETURNING par_refno INTO l_tmp_par_refno;
  
  create_or_maintain_address(p_refno=>l_tmp_par_refno,p_fao_code=>'PAR',p_adr_address_line_1=>'34 Playground Lane',
    p_adr_address_line_2=>'Garden Village',p_adr_town=>'NORTHTOWN',p_adr_county=>'Northshire',p_adr_postcode=>'RG1 1PB');

  history_tables_api.snapshot_party( p_par_refno=>l_tmp_par_refno,p_snapshot_src_vn=>NULL,p_parh_version=>l_h_version);

  INSERT INTO lbtt_return_party_links (
    lpli_par_refno,lpli_lbtt_tare_refno,lpli_lbtt_version,
    lpli_flpt_type,lpli_flpt_srv_code,lpli_flpt_frd_domain,lpli_flpt_wrk_refno,
    lpli_buyer_seller_linked_ind,lpli_authority_ind,lpli_orig_authority_ind,lpli_parh_version
) VALUES (
    l_tmp_par_refno,l_tare_refno,1,
    'BUYER','LBTT','RETURNPARTYLINKS',1,
    'N','N','N',l_h_version);
   
   INSERT INTO parties
    (par_refno,par_type,par_per_surname,par_per_forename,par_marketing_ind)
   VALUES
    (par_refno_seq.nextval,'PER','Seller-First','Jane','N')
   RETURNING par_refno INTO l_tmp_par_refno;
  
  create_or_maintain_address(p_refno=>l_tmp_par_refno,p_fao_code=>'PAR',p_adr_address_line_1=>'35 Cedar Rd',
    p_adr_address_line_2=>'Garden Village',p_adr_town=>'NORTHTOWN',p_adr_county=>'Northshire',p_adr_postcode=>'RG1 1PB');

  history_tables_api.snapshot_party( p_par_refno=>l_tmp_par_refno,p_snapshot_src_vn=>NULL,p_parh_version=>l_h_version);
    
  INSERT INTO lbtt_return_party_links (
    lpli_par_refno,lpli_lbtt_tare_refno,lpli_lbtt_version,
    lpli_flpt_type,lpli_flpt_srv_code,lpli_flpt_frd_domain,lpli_flpt_wrk_refno,
    lpli_buyer_seller_linked_ind,lpli_authority_ind,lpli_orig_authority_ind,lpli_parh_version
) VALUES (
    l_tmp_par_refno,l_tare_refno,1,
    'SELLER','LBTT','RETURNPARTYLINKS',1,
    'N','N','N',l_h_version); 
    
    -- Insert the agent and the link to the account
    history_tables_api.snapshot_party( p_par_refno=>l_par_refno,p_snapshot_src_vn=>NULL,p_parh_version=>l_h_version);

    INSERT INTO lbtt_return_party_links (
    lpli_par_refno,lpli_lbtt_tare_refno,lpli_lbtt_version,
    lpli_flpt_type,lpli_flpt_srv_code,lpli_flpt_frd_domain,lpli_flpt_wrk_refno,
    lpli_buyer_seller_linked_ind,lpli_authority_ind,lpli_orig_authority_ind,lpli_parh_version
   ) VALUES (
    l_par_refno,l_tare_refno,1,
    'AGENT','LBTT','RETURNPARTYLINKS',1,
    'Y','N','N',l_h_version);
    
   -- Open repayment case	
  INSERT INTO cases (
    case_refno,case_reference,
    case_caty_type,case_caty_srv_code,case_caty_wrk_refno,
    case_cast_status,case_casr_reason,case_description,
    case_automatic_ind,case_fcas_source,case_fcas_frd_domain,case_fcas_wrk_refno,case_fcas_srv_code,
    case_receipt_date,case_all_information_date,
    case_fobt_type,case_fobt_frd_domain,case_fobt_wrk_refno,case_fobt_srv_code,case_related_reference
  ) VALUES (
    case_seq.nextval,'PORTAL.RS3000004DDDD',
    'ADS REPAYMENT','LBTT',1,
    'OPEN','UNAUTHENTICATED ADS REPAYMENT','Test Data',
    'Y','DASHBOARD','CASESOURCES',1,'LBTT',
    '01-SEP-2019','01-SEP-2019',
    'RETURN','OBJECT TYPES',1,'LBTT','RS3000004DDDD'
  )
  returning case_refno INTO l_case_refno;

   -- repayment request
  INSERT INTO return_repayments (
    rrep_refno,rrep_reference,rrep_type,rrep_tare_refno,rrep_version,
    rrep_par_refno,rrep_frer_reason,rrep_frer_frd_domain,rrep_frer_wrk_refno,rrep_frer_srv_code,
    rrep_case_refno,
    rrep_amount_claimed,rrep_account_holder,rrep_bank_account_no,rrep_bank_sort_code,rrep_bank_name,
    rrep_submitted_by,rrep_submitted_date,rrep_ads_family_ind
  ) VALUES (
    rrep_seq.nextval,'RS3000004DDDD','PRE',l_tare_refno,1,
    l_par_refno,'ADS','CLAIMREASONS',1,'LBTT',
    l_case_refno,
    100,'Mickey Mouse','12345678','00-00-00','Floyds',
    user,'01-SEP-2019','N');
  
  --------
  -- FINAL lease more than 12 months
  INSERT INTO tax_returns
   (tare_refno, tare_reference, tare_srv_code)
  VALUES
   (tare_seq.nextval,'RS2000003BBBB','LBTT')
  returning tare_refno INTO l_tare_refno;

  INSERT INTO lbtt_returns (
    lbtt_tare_refno,lbtt_version,lbtt_source,lbtt_latest_draft_ind,lbtt_agent_reference,
    lbtt_fpty_type,lbtt_fpty_frd_domain,lbtt_fpty_srv_code,lbtt_fpty_wrk_refno,
    lbtt_flbt_type,lbtt_flbt_frd_domain,lbtt_flbt_srv_code,lbtt_flbt_wrk_refno,
    lbtt_effective_date,lbtt_submitted_date,lbtt_relevant_date,lbtt_contract_date,
    lbtt_business_ind,lbtt_moveables_ind,lbtt_stock_ind,lbtt_goodwill_ind,lbtt_other_ind,
    lbtt_non_chargeable,lbtt_total_vat,lbtt_remaining_chargeable,
    lbtt_exchange_ind,lbtt_uk_ind,lbtt_linked_ind,lbtt_previous_option_ind,
    lbtt_linked_consideration,lbtt_total_consideration,
    lbtt_calculated,lbtt_due_before_reliefs,lbtt_total_reliefs,lbtt_tax_due,
    lbtt_orig_calculated,lbtt_orig_due_before_reliefs,lbtt_orig_total_reliefs,lbtt_orig_tax_due,
    lbtt_ads_due_ind,lbtt_ads_due,lbtt_orig_ads_due,
    lbtt_fpay_method,lbtt_fpay_frd_domain,lbtt_fpay_srv_code,lbtt_fpay_wrk_refno,
    lbtt_lease_start_date,lbtt_lease_end_date,lbtt_annual_rent,
    lbtt_same_rent_each_year_ind,lbtt_net_present_value,lbtt_relevant_rent,
    lbtt_lease_premium,lbtt_premium_tax_due,lbtt_npv_tax_due 
) VALUES (
    l_tare_refno,1,'P','L','YY/XXXXX02-99',
    '3','PROPERTYTYPE','SYS',1, -- Non Residential
    'LEASERET','RETURN TYPE','LBTT',1,
    NON_AMENDABLE_DATE,NON_AMENDABLE_DATE,NON_AMENDABLE_DATE,NON_AMENDABLE_DATE,
    'N','N','N','N','N',
    0,0,0,
    'N','N','N','N',
    0,100000,
    1000,1000,0,1000,
    1000,1000,0,1000,
    'N',0,0,
    'BACS','PAYMENT TYPE','LBTT',1,
    '10-OCT-2022','08-OCT-2026',350000,'N',
    1304875.26,351000,352000,500,600);

  INSERT INTO cases (
    case_refno,case_reference,
    case_caty_type,case_caty_srv_code,case_caty_wrk_refno,
    case_cast_status,case_casr_reason,
    case_automatic_ind,case_fcas_source,case_fcas_frd_domain,case_fcas_wrk_refno,case_fcas_srv_code,
    case_receipt_date,case_all_information_date,
    case_fobt_type,case_fobt_frd_domain,case_fobt_wrk_refno,case_fobt_srv_code,case_related_reference
  ) VALUES (
    case_seq.nextval,'PORTAL.RS2000003BBBB',
    'RETURN','LBTT',1,
    'CLOSED','AUTOCLOSED',
    'Y','ONLINEFORM','CASESOURCES',1,'LBTT',
    '01-SEP-2019','01-SEP-2019',
    'RETURN','CASEOBJECTTYPES',1,'LBTT','RS2000003BBBB'
  ) 
  returning case_refno INTO l_case_refno;

  INSERT INTO case_return_links (
    crli_tare_refno, crli_case_refno
  ) VALUES (
    l_tare_refno,l_case_refno
  );

  INSERT INTO lbtt_yearly_rents (
    lbyr_lbtt_tare_refno, lbyr_lbtt_version, lbyr_year, lbyr_rent
  ) VALUES (
      l_tare_refno,1,1,350100
  );

  INSERT INTO lbtt_yearly_rents (
    lbyr_lbtt_tare_refno, lbyr_lbtt_version, lbyr_year, lbyr_rent
  ) VALUES (
      l_tare_refno,1,2,360200
  );

  INSERT INTO lbtt_yearly_rents (
    lbyr_lbtt_tare_refno, lbyr_lbtt_version, lbyr_year, lbyr_rent
  ) VALUES (
      l_tare_refno,1,3,370200
  );

  INSERT INTO lbtt_yearly_rents (
    lbyr_lbtt_tare_refno, lbyr_lbtt_version, lbyr_year, lbyr_rent
  ) VALUES (
      l_tare_refno,1,4,340200
  );    
  
  INSERT INTO properties (
    pro_lau_code,pro_lau_frd_domain,pro_lau_wrk_refno, pro_lau_srv_code
  ) VALUES (
    '9055','LAU',1, 'SYS'
  ) returning pro_refno INTO l_pro_refno;
  
   create_or_maintain_address(p_refno=>l_pro_refno,p_fao_code=>'PRO',p_adr_address_line_1=>'Marks & Spencer plc',
     p_adr_address_line_2=>'Unit 14',p_adr_town=>'Glasgow',p_adr_county=>'Lanarkshire',p_adr_postcode=>'G1 3SQ',p_adr_type=>'PHYSICAL',p_adr_country=>'SCO');
 
   history_tables_api.snapshot_property( p_pro_refno=>l_pro_refno,p_snapshot_src_vn=>NULL,p_proh_version=>l_h_version);
                             
  INSERT INTO lbtt_properties (
    lppr_pro_refno,lppr_lbtt_tare_refno,lppr_lbtt_version,lppr_proh_version
  ) VALUES (
    l_pro_refno,l_tare_refno,1,l_h_version);
    

  INSERT INTO parties
    (par_refno,par_type,par_per_surname,par_per_forename,par_marketing_ind,par_per_ni_no)
  VALUES
    (par_refno_seq.nextval,'PER','Buyer-First','Derek','N','RW471856D')
  RETURNING par_refno INTO l_tmp_par_refno;

  create_or_maintain_cde(p_par_refno=>l_tmp_par_refno,p_cde_cme_code=>'EMAIL',p_value=>'DerekBuyer@necsws.com');
  create_or_maintain_cde(p_par_refno=>l_tmp_par_refno,p_cde_cme_code=>'PHONE',p_value=>'07700904321');
  create_or_maintain_address(p_refno=>l_tmp_par_refno,p_fao_code=>'PAR',p_adr_address_line_1=>'22 Coronation Street',
    p_adr_address_line_2=>'Garden Village',p_adr_town=>'NORTHTOWN',p_adr_county=>'Northshire',p_adr_postcode=>'RG1 1PB',
    p_adr_type => 'PHYSICAL');

  history_tables_api.snapshot_party( p_par_refno=>l_tmp_par_refno,p_snapshot_src_vn=>NULL,p_parh_version=>l_h_version);

  INSERT INTO lbtt_return_party_links (
    lpli_par_refno,lpli_lbtt_tare_refno,lpli_lbtt_version,
    lpli_flpt_type,lpli_flpt_srv_code,lpli_flpt_frd_domain,lpli_flpt_wrk_refno,
    lpli_buyer_seller_linked_ind,lpli_authority_ind,lpli_orig_authority_ind,lpli_parh_version,
    lpli_contact_parh_version, lpli_contact_par_refno, lpli_acting_trustee_ind
) VALUES (
    l_tmp_par_refno,l_tare_refno,1,
    'BUYER','LBTT','RETURNPARTYLINKS',1,
    'N','N','N',l_h_version,1,l_tmp_par_refno,'Y');
   
   INSERT INTO parties
    (par_refno,par_type,par_per_surname,par_per_forename,par_marketing_ind)
   VALUES
    (par_refno_seq.nextval,'PER','Seller-First','Fiona','N')
   RETURNING par_refno INTO l_tmp_par_refno;
  
  create_or_maintain_address(p_refno=>l_tmp_par_refno,p_fao_code=>'PAR',p_adr_address_line_1=>'22 Lawn Rd',
    p_adr_address_line_2=>'Garden Village',p_adr_town=>'NORTHTOWN',p_adr_county=>'Northshire',p_adr_postcode=>'RG1 1PB');

  history_tables_api.snapshot_party( p_par_refno=>l_tmp_par_refno,p_snapshot_src_vn=>NULL,p_parh_version=>l_h_version);
    
  INSERT INTO lbtt_return_party_links (
    lpli_par_refno,lpli_lbtt_tare_refno,lpli_lbtt_version,
    lpli_flpt_type,lpli_flpt_srv_code,lpli_flpt_frd_domain,lpli_flpt_wrk_refno,
    lpli_buyer_seller_linked_ind,lpli_authority_ind,lpli_orig_authority_ind,lpli_parh_version
) VALUES (
    l_tmp_par_refno,l_tare_refno,1,
    'SELLER','LBTT','RETURNPARTYLINKS',1,
    'N','N','N',l_h_version); 
    
    -- Insert the agent and the link to the account
    history_tables_api.snapshot_party( p_par_refno=>l_par_refno,p_snapshot_src_vn=>NULL,p_parh_version=>l_h_version);

    INSERT INTO lbtt_return_party_links (
    lpli_par_refno,lpli_lbtt_tare_refno,lpli_lbtt_version,
    lpli_flpt_type,lpli_flpt_srv_code,lpli_flpt_frd_domain,lpli_flpt_wrk_refno,
    lpli_buyer_seller_linked_ind,lpli_authority_ind,lpli_orig_authority_ind,lpli_parh_version
   ) VALUES (
    l_par_refno,l_tare_refno,1,
    'AGENT','LBTT','RETURNPARTYLINKS',1,
    'Y','N','N',l_h_version);
  --------
  -- FINAL lease less than 12 months
  INSERT INTO tax_returns
   (tare_refno, tare_reference, tare_srv_code)
  VALUES
   (tare_seq.nextval,'RS3000003EEEE','LBTT')
  returning tare_refno INTO l_tare_refno;

  INSERT INTO lbtt_returns (
    lbtt_tare_refno,lbtt_version,lbtt_source,lbtt_latest_draft_ind,lbtt_agent_reference,
    lbtt_fpty_type,lbtt_fpty_frd_domain,lbtt_fpty_srv_code,lbtt_fpty_wrk_refno,
    lbtt_flbt_type,lbtt_flbt_frd_domain,lbtt_flbt_srv_code,lbtt_flbt_wrk_refno,
    lbtt_effective_date,lbtt_submitted_date,lbtt_relevant_date,lbtt_contract_date,
    lbtt_business_ind,lbtt_moveables_ind,lbtt_stock_ind,lbtt_goodwill_ind,lbtt_other_ind,
    lbtt_non_chargeable,lbtt_total_vat,lbtt_remaining_chargeable,
    lbtt_exchange_ind,lbtt_uk_ind,lbtt_linked_ind,lbtt_previous_option_ind,
    lbtt_linked_consideration,lbtt_total_consideration,
    lbtt_calculated,lbtt_due_before_reliefs,lbtt_total_reliefs,lbtt_tax_due,
    lbtt_orig_calculated,lbtt_orig_due_before_reliefs,lbtt_orig_total_reliefs,lbtt_orig_tax_due,
    lbtt_ads_due_ind,lbtt_ads_due,lbtt_orig_ads_due,
    lbtt_fpay_method,lbtt_fpay_frd_domain,lbtt_fpay_srv_code,lbtt_fpay_wrk_refno
) VALUES (
    l_tare_refno,1,'P','L','YY/XXXXX02-99',
    '3','PROPERTYTYPE','SYS',1, -- Non Residential
    'LEASERET','RETURN TYPE','LBTT',1,
    '01-OCT-2019','01-OCT-2019','01-OCT-2019','01-OCT-2019',
    'N','N','N','N','N',
    0,0,0,
    'N','N','N','N',
    0,100000,
    1000,1000,0,1000,
    1000,1000,0,1000,
    'N',0,0,
    'BACS','PAYMENT TYPE','LBTT',1);
    
  INSERT INTO properties (
    pro_lau_code,pro_lau_frd_domain,pro_lau_wrk_refno, pro_lau_srv_code
  ) VALUES (
    '9055','LAU',1, 'SYS'
  ) returning pro_refno INTO l_pro_refno;
  
   create_or_maintain_address(p_refno=>l_pro_refno,p_fao_code=>'PRO',p_adr_address_line_1=>'31 Thorn Avenue',
     p_adr_address_line_2=>'',p_adr_town=>'Hemel Hempstead',p_adr_county=>'Hertfordshire',p_adr_postcode=>'HP2 7DX',p_adr_type=>'PHYSICAL');
 
   history_tables_api.snapshot_property( p_pro_refno=>l_pro_refno,p_snapshot_src_vn=>NULL,p_proh_version=>l_h_version);
                             
  INSERT INTO lbtt_properties (
    lppr_pro_refno,lppr_lbtt_tare_refno,lppr_lbtt_version,lppr_proh_version
  ) VALUES (
    l_pro_refno,l_tare_refno,1,l_h_version);

  INSERT INTO parties
    (par_refno,par_type,par_per_surname,par_per_forename,par_marketing_ind)
  VALUES
    (par_refno_seq.nextval,'PER','Buyer-First','Michael','N')
  RETURNING par_refno INTO l_tmp_par_refno;
  
  create_or_maintain_address(p_refno=>l_tmp_par_refno,p_fao_code=>'PAR',p_adr_address_line_1=>'32 Crown Street',
    p_adr_address_line_2=>'Garden Village',p_adr_town=>'NORTHTOWN',p_adr_county=>'Northshire',p_adr_postcode=>'RG1 1PB');

  history_tables_api.snapshot_party( p_par_refno=>l_tmp_par_refno,p_snapshot_src_vn=>NULL,p_parh_version=>l_h_version);

  INSERT INTO lbtt_return_party_links (
    lpli_par_refno,lpli_lbtt_tare_refno,lpli_lbtt_version,
    lpli_flpt_type,lpli_flpt_srv_code,lpli_flpt_frd_domain,lpli_flpt_wrk_refno,
    lpli_buyer_seller_linked_ind,lpli_authority_ind,lpli_orig_authority_ind,lpli_parh_version
) VALUES (
    l_tmp_par_refno,l_tare_refno,1,
    'BUYER','LBTT','RETURNPARTYLINKS',1,
    'N','N','N',l_h_version);
   
   INSERT INTO parties
    (par_refno,par_type,par_per_surname,par_per_forename,par_marketing_ind)
   VALUES
    (par_refno_seq.nextval,'PER','Seller-First','Nancy','N')
   RETURNING par_refno INTO l_tmp_par_refno;
  
  create_or_maintain_address(p_refno=>l_tmp_par_refno,p_fao_code=>'PAR',p_adr_address_line_1=>'32 Path Rd',
    p_adr_address_line_2=>'Garden Village',p_adr_town=>'NORTHTOWN',p_adr_county=>'Northshire',p_adr_postcode=>'RG1 1PB');

  history_tables_api.snapshot_party( p_par_refno=>l_tmp_par_refno,p_snapshot_src_vn=>NULL,p_parh_version=>l_h_version);
    
  INSERT INTO lbtt_return_party_links (
    lpli_par_refno,lpli_lbtt_tare_refno,lpli_lbtt_version,
    lpli_flpt_type,lpli_flpt_srv_code,lpli_flpt_frd_domain,lpli_flpt_wrk_refno,
    lpli_buyer_seller_linked_ind,lpli_authority_ind,lpli_orig_authority_ind,lpli_parh_version
) VALUES (
    l_tmp_par_refno,l_tare_refno,1,
    'SELLER','LBTT','RETURNPARTYLINKS',1,
    'N','N','N',l_h_version); 
    
    -- Insert the agent and the link to the account
    history_tables_api.snapshot_party( p_par_refno=>l_par_refno,p_snapshot_src_vn=>NULL,p_parh_version=>l_h_version);

    INSERT INTO lbtt_return_party_links (
    lpli_par_refno,lpli_lbtt_tare_refno,lpli_lbtt_version,
    lpli_flpt_type,lpli_flpt_srv_code,lpli_flpt_frd_domain,lpli_flpt_wrk_refno,
    lpli_buyer_seller_linked_ind,lpli_authority_ind,lpli_orig_authority_ind,lpli_parh_version
   ) VALUES (
    l_par_refno,l_tare_refno,1,
    'AGENT','LBTT','RETURNPARTYLINKS',1,
    'Y','N','N',l_h_version);
    
     -- Lease return has been disregarded (whole return)
    INSERT INTO tax_returns
      (tare_refno,tare_reference,tare_srv_code,tare_disregard_ind) 
    VALUES 
      (tare_seq.nextval,'RS3000003FFFF','LBTT','Y') 
    RETURNING tare_refno INTO L_TARE_REFNO;

     INSERT INTO lbtt_returns 
      (lbtt_tare_refno,
      lbtt_version,lbtt_source,lbtt_latest_draft_ind,lbtt_agent_reference,
      lbtt_fpty_type,lbtt_fpty_frd_domain,lbtt_fpty_srv_code,lbtt_fpty_wrk_refno,
      lbtt_flbt_type,lbtt_flbt_frd_domain,lbtt_flbt_srv_code,lbtt_flbt_wrk_refno,
      lbtt_effective_date,lbtt_submitted_date,lbtt_relevant_date,lbtt_contract_date,
      lbtt_business_ind,lbtt_moveables_ind,lbtt_stock_ind,lbtt_goodwill_ind,lbtt_other_ind,
      lbtt_non_chargeable,lbtt_total_vat,lbtt_remaining_chargeable,lbtt_exchange_ind,
      lbtt_uk_ind,lbtt_linked_ind,lbtt_previous_option_ind,lbtt_linked_consideration,
      lbtt_total_consideration,lbtt_calculated,lbtt_due_before_reliefs,lbtt_total_reliefs,
      lbtt_tax_due,lbtt_orig_calculated,lbtt_orig_due_before_reliefs,lbtt_orig_total_reliefs,
      lbtt_orig_tax_due,lbtt_ads_due_ind,lbtt_ads_due,lbtt_orig_ads_due,lbtt_fpay_method,
      lbtt_fpay_frd_domain,lbtt_fpay_srv_code,lbtt_fpay_wrk_refno,lbtt_disregard_ind) 
     VALUES 
      (l_tare_refno,1,'P','','YY/XXXXX02-99','3','PROPERTYTYPE','SYS',1, -- Non Residential
      'LEASERET','RETURN TYPE','LBTT',1,'01-OCT-2019','01-OCT-2019','01-OCT-2019',
      '01-OCT-2019','N','N','N','N','N',0,0,0,'N','N','N','N',0,100000,1000,1000,0,
      1000,1000,1000,0,1000,'N',0,0,'BACS','PAYMENT TYPE','LBTT',1,'Y');

     INSERT INTO properties 
     (pro_lau_code,pro_lau_frd_domain,pro_lau_wrk_refno,pro_lau_srv_code) 
     VALUES 
      ('9055','LAU',1,'SYS') 
     RETURNING pro_refno INTO l_pro_refno;

     CREATE_OR_MAINTAIN_ADDRESS(p_refno=>l_pro_refno, p_fao_code=>'PRO', p_adr_address_line_1=>'1131 Thorn Avenue',
     p_adr_address_line_2=>'', p_adr_town=>'Hemel Hempstead', p_adr_county=>'Hertfordshire', p_adr_postcode=>'HP2 7DX', p_adr_type=>'PHYSICAL');

     HISTORY_TABLES_API.SNAPSHOT_PROPERTY(p_pro_refno=>l_pro_refno,
      p_snapshot_src_vn=>NULL,p_proh_version=>l_h_version);

     INSERT INTO lbtt_properties 
      (lppr_pro_refno,lppr_lbtt_tare_refno,lppr_lbtt_version,lppr_proh_version) 
     VALUES 
      (l_pro_refno,l_tare_refno,1,l_h_version);

     INSERT INTO parties 
      (par_refno,par_type,par_per_surname,par_per_forename,par_marketing_ind)
     VALUES 
      (par_refno_seq.nextval,'PER','Buyer-First','DISREGARD','N')
     RETURNING par_refno INTO l_tmp_par_refno;

     CREATE_OR_MAINTAIN_ADDRESS(p_refno=>l_tmp_par_refno, p_fao_code=>'PAR', p_adr_address_line_1=>'1132 Crown Street',
     p_adr_address_line_2=>'Garden Village', p_adr_town=>'NORTHTOWN', p_adr_county=>'Northshire', p_adr_postcode=>'RG1 1PB');

     HISTORY_TABLES_API.SNAPSHOT_PARTY(
      p_par_refno=>l_tmp_par_refno,
      p_snapshot_src_vn=>NULL,
      p_parh_version=>l_h_version);

     INSERT INTO lbtt_return_party_links 
      (lpli_par_refno,lpli_lbtt_tare_refno,lpli_lbtt_version,lpli_flpt_type,lpli_flpt_srv_code,lpli_flpt_frd_domain,
      lpli_flpt_wrk_refno,lpli_buyer_seller_linked_ind,lpli_authority_ind,lpli_orig_authority_ind,lpli_parh_version)
     VALUES 
      (l_tmp_par_refno,l_tare_refno,1,'BUYER','LBTT','RETURNPARTYLINKS',1,'N','N','N',l_h_version);

     INSERT INTO parties 
      (par_refno,par_type,par_per_surname,par_per_forename,par_marketing_ind)
     VALUES 
     (par_refno_seq.nextval,'PER','Seller-First','Disregard','N')
     RETURNING par_refno INTO l_tmp_par_refno;

     CREATE_OR_MAINTAIN_ADDRESS(p_refno=>l_tmp_par_refno, p_fao_code=>'PAR', p_adr_address_line_1=>'1132 Path Rd',
     p_adr_address_line_2=>'Garden Village', p_adr_town=>'NORTHTOWN', p_adr_county=>'Northshire', p_adr_postcode=>'RG1 1PB');

     HISTORY_TABLES_API.SNAPSHOT_PARTY(
      p_par_refno=>l_tmp_par_refno,
      p_snapshot_src_vn=>NULL,
      p_parh_version=>l_h_version);

     INSERT INTO lbtt_return_party_links 
      (lpli_par_refno,lpli_lbtt_tare_refno,lpli_lbtt_version,lpli_flpt_type,lpli_flpt_srv_code,
      lpli_flpt_frd_domain,lpli_flpt_wrk_refno,lpli_buyer_seller_linked_ind,lpli_authority_ind,
      lpli_orig_authority_ind,lpli_parh_version) 
     VALUES 
      (l_tmp_par_refno,l_tare_refno,1,'SELLER','LBTT','RETURNPARTYLINKS',1,'N','N','N',l_h_version);

    -- Insert the agent and the link to the account
     HISTORY_TABLES_API.SNAPSHOT_PARTY(
      p_par_refno=>l_par_refno,
      p_snapshot_src_vn=>NULL,
      p_parh_version=>l_h_version);

     INSERT INTO lbtt_return_party_links 
      (lpli_par_refno,lpli_lbtt_tare_refno,lpli_lbtt_version,lpli_flpt_type,lpli_flpt_srv_code,lpli_flpt_frd_domain,
      lpli_flpt_wrk_refno,lpli_buyer_seller_linked_ind,lpli_authority_ind,lpli_orig_authority_ind,lpli_parh_version)
     VALUES 
      (l_par_refno,l_tare_refno,1,'AGENT','LBTT','RETURNPARTYLINKS',1,'Y','N','N',l_h_version);

    -- Lease return has been disregarded (one verion)
     INSERT INTO tax_returns 
      (tare_refno,tare_reference,tare_srv_code)
     VALUES 
      (tare_seq.nextval,'RS3000003GGGG','LBTT') 
     RETURNING TARE_REFNO INTO L_TARE_REFNO;

     INSERT INTO lbtt_returns 
      (lbtt_tare_refno,lbtt_version,lbtt_source,lbtt_latest_draft_ind,lbtt_agent_reference,lbtt_fpty_type,
      lbtt_fpty_frd_domain,lbtt_fpty_srv_code,lbtt_fpty_wrk_refno,lbtt_flbt_type,lbtt_flbt_frd_domain,lbtt_flbt_srv_code,
      lbtt_flbt_wrk_refno,lbtt_effective_date,lbtt_submitted_date,lbtt_relevant_date,lbtt_contract_date,lbtt_business_ind,
      lbtt_moveables_ind,lbtt_stock_ind,lbtt_goodwill_ind,lbtt_other_ind,lbtt_non_chargeable,lbtt_total_vat,lbtt_remaining_chargeable,
      lbtt_exchange_ind,lbtt_uk_ind,lbtt_linked_ind,lbtt_previous_option_ind,lbtt_linked_consideration,lbtt_total_consideration,
      lbtt_calculated,lbtt_due_before_reliefs,lbtt_total_reliefs,lbtt_tax_due,lbtt_orig_calculated,lbtt_orig_due_before_reliefs,
      lbtt_orig_total_reliefs,lbtt_orig_tax_due,lbtt_ads_due_ind,lbtt_ads_due,lbtt_orig_ads_due,lbtt_fpay_method,lbtt_fpay_frd_domain,
      lbtt_fpay_srv_code,lbtt_fpay_wrk_refno)
     VALUES 
     (l_tare_refno,1,'P','L','YY/XXXXX02-99','3','PROPERTYTYPE','SYS',1, -- Non Residential
      'LEASERET','RETURN TYPE','LBTT',1,'02-OCT-2019','02-OCT-2019','02-OCT-2019','02-OCT-2019',
      'N','N','N','N','N',0,0,0,'N','N','N','N',0,100000,1000,1000,0,1000,1000,1000,0,1000,'N',0,0,
      'BACS','PAYMENT TYPE','LBTT',1);

     INSERT INTO properties 
      (pro_lau_code,pro_lau_frd_domain,pro_lau_wrk_refno,pro_lau_srv_code)
     VALUES 
     ('9055','LAU',1,'SYS')
     RETURNING pro_refno INTO l_pro_refno;

     CREATE_OR_MAINTAIN_ADDRESS(p_refno=>l_pro_refno, p_fao_code=>'PRO', p_adr_address_line_1=>'2231 Thorn Avenue',
     p_adr_address_line_2=>'', p_adr_town=>'Hemel Hempstead', p_adr_county=>'Hertfordshire', p_adr_postcode=>'HP2 7DX', p_adr_type=>'PHYSICAL');

     HISTORY_TABLES_API.SNAPSHOT_PROPERTY(
      p_pro_refno=>l_pro_refno,
      p_snapshot_src_vn=>NULL,
      p_proh_version=>l_h_version);

     INSERT INTO lbtt_properties 
      (lppr_pro_refno,lppr_lbtt_tare_refno,lppr_lbtt_version,lppr_proh_version)
     VALUES 
      (l_pro_refno,l_tare_refno,1,l_h_version);

     INSERT INTO parties 
      (par_refno,par_type,par_per_surname,par_per_forename,par_marketing_ind) 
     VALUES 
      (par_refno_seq.nextval,'PER','Buyer-Second','DISREGARD','N') 
     RETURNING par_refno INTO l_tmp_par_refno;

     CREATE_OR_MAINTAIN_ADDRESS(p_refno=>l_tmp_par_refno, p_fao_code=>'PAR', p_adr_address_line_1=>'2232 Crown Street',
     p_adr_address_line_2=>'Garden Village', p_adr_town=>'NORTHTOWN', p_adr_county=>'Northshire', p_adr_postcode=>'RG1 1PB');

     HISTORY_TABLES_API.SNAPSHOT_PARTY(
      p_par_refno=>l_tmp_par_refno,
      p_snapshot_src_vn=>NULL,
      p_parh_version=>l_h_version);

     INSERT INTO lbtt_return_party_links 
      (lpli_par_refno,lpli_lbtt_tare_refno,lpli_lbtt_version,lpli_flpt_type,lpli_flpt_srv_code,lpli_flpt_frd_domain,
      lpli_flpt_wrk_refno,lpli_buyer_seller_linked_ind,lpli_authority_ind,lpli_orig_authority_ind,lpli_parh_version) 
     VALUES 
      (l_tmp_par_refno,l_tare_refno,1,'BUYER','LBTT','RETURNPARTYLINKS',1,'N','N','N',l_h_version);

     INSERT INTO parties 
      (par_refno,par_type,par_per_surname,par_per_forename,par_marketing_ind) 
     VALUES 
      (par_refno_seq.nextval,'PER','Seller-Second','Disregard','N') 
     RETURNING par_refno INTO l_tmp_par_refno;

     CREATE_OR_MAINTAIN_ADDRESS(p_refno=>l_tmp_par_refno, p_fao_code=>'PAR', p_adr_address_line_1=>'2232 Path Rd',
     p_adr_address_line_2=>'Garden Village', p_adr_town=>'NORTHTOWN', p_adr_county=>'Northshire', p_adr_postcode=>'RG1 1PB');

     HISTORY_TABLES_API.SNAPSHOT_PARTY(
      p_par_refno=>l_tmp_par_refno,
      p_snapshot_src_vn=>NULL,
      p_parh_version=>l_h_version);

     INSERT INTO lbtt_return_party_links 
      (lpli_par_refno,lpli_lbtt_tare_refno,lpli_lbtt_version,lpli_flpt_type,lpli_flpt_srv_code,lpli_flpt_frd_domain,
      lpli_flpt_wrk_refno,lpli_buyer_seller_linked_ind,lpli_authority_ind,lpli_orig_authority_ind,lpli_parh_version)
     VALUES 
      (l_tmp_par_refno,l_tare_refno,1,'SELLER','LBTT','RETURNPARTYLINKS',1,'N','N','N',l_h_version);

    -- Insert the agent and the link to the account
     HISTORY_TABLES_API.SNAPSHOT_PARTY(
      p_par_refno=>l_par_refno,
      p_snapshot_src_vn=>NULL,
      p_parh_version=>l_h_version);

     INSERT INTO lbtt_return_party_links 
      (lpli_par_refno,lpli_lbtt_tare_refno,lpli_lbtt_version,lpli_flpt_type,lpli_flpt_srv_code,lpli_flpt_frd_domain,
      lpli_flpt_wrk_refno,lpli_buyer_seller_linked_ind,lpli_authority_ind,lpli_orig_authority_ind,lpli_parh_version)
     VALUES 
      (l_par_refno,l_tare_refno,1,'AGENT','LBTT','RETURNPARTYLINKS',1,'Y','N','N',l_h_version);

    -- V2
     INSERT INTO lbtt_returns 
      (lbtt_tare_refno,lbtt_version,lbtt_source,lbtt_latest_draft_ind,lbtt_agent_reference,lbtt_fpty_type,lbtt_fpty_frd_domain,
      lbtt_fpty_srv_code,lbtt_fpty_wrk_refno,lbtt_flbt_type,lbtt_flbt_frd_domain,lbtt_flbt_srv_code,lbtt_flbt_wrk_refno,lbtt_effective_date,
      lbtt_submitted_date,lbtt_relevant_date,lbtt_contract_date,lbtt_business_ind,lbtt_moveables_ind,lbtt_stock_ind,lbtt_goodwill_ind,
      lbtt_other_ind,lbtt_non_chargeable,lbtt_total_vat,lbtt_remaining_chargeable,lbtt_exchange_ind,lbtt_uk_ind,lbtt_linked_ind,
      lbtt_previous_option_ind,lbtt_linked_consideration,lbtt_total_consideration,lbtt_calculated,lbtt_due_before_reliefs,lbtt_total_reliefs,
      lbtt_tax_due,lbtt_orig_calculated,lbtt_orig_due_before_reliefs,lbtt_orig_total_reliefs,lbtt_orig_tax_due,lbtt_ads_due_ind,lbtt_ads_due,
      lbtt_orig_ads_due,lbtt_fpay_method,lbtt_fpay_frd_domain,lbtt_fpay_srv_code,lbtt_fpay_wrk_refno,lbtt_disregard_ind) 
     VALUES 
      (L_TARE_REFNO,2,'P','','YY/XXXXX02-99','3','PROPERTYTYPE','SYS',1, -- Non Residential
      'LEASERET','RETURN TYPE','LBTT',1,'03-OCT-2019','03-OCT-2019','03-OCT-2019','03-OCT-2019',
      'N','N','N','N','N',0,0,0,'N','N','N','N',0,100000,1000,1000,0,1000,1000,1000,0,1000,'N',
      0,0,'BACS','PAYMENT TYPE','LBTT',1,'Y');

     INSERT INTO properties 
      (pro_lau_code,pro_lau_frd_domain,pro_lau_wrk_refno,pro_lau_srv_code)
     VALUES 
      ('9055','LAU',1,'SYS') 
     RETURNING pro_refno INTO l_pro_refno;

     CREATE_OR_MAINTAIN_ADDRESS(p_refno=>l_pro_refno, p_fao_code=>'PRO', p_adr_address_line_1=>'2231 Thorn Avenue',
      p_adr_address_line_2=>'', p_adr_town=>'Hemel Hempstead', p_adr_county=>'Hertfordshire', p_adr_postcode=>'HP2 7DX', p_adr_type=>'PHYSICAL');

     HISTORY_TABLES_API.SNAPSHOT_PROPERTY(
      p_pro_refno=>l_pro_refno,
      p_snapshot_src_vn=>NULL,
      p_proh_version=>l_h_version);

     INSERT INTO lbtt_properties 
      (lppr_pro_refno,lppr_lbtt_tare_refno,lppr_lbtt_version,lppr_proh_version)
     VALUES 
      (l_pro_refno,l_tare_refno,1,l_h_version);

     INSERT INTO parties 
      (par_refno,par_type,par_per_surname,par_per_forename,par_marketing_ind) 
     VALUES 
      (par_refno_seq.nextval,'PER','Buyer-Second','DISREGARD','N')
     RETURNING par_refno INTO l_tmp_par_refno;

     CREATE_OR_MAINTAIN_ADDRESS(p_refno=>l_tmp_par_refno, p_fao_code=>'PAR', p_adr_address_line_1=>'2232 Crown Street',
      p_adr_address_line_2=>'Garden Village', p_adr_town=>'NORTHTOWN', p_adr_county=>'Northshire', p_adr_postcode=>'RG1 1PB');

     HISTORY_TABLES_API.SNAPSHOT_PARTY(
      p_par_refno=>l_tmp_par_refno,
      p_snapshot_src_vn=>NULL,
      p_parh_version=>l_h_version);

     INSERT INTO lbtt_return_party_links 
      (lpli_par_refno,lpli_lbtt_tare_refno,lpli_lbtt_version,lpli_flpt_type,lpli_flpt_srv_code,lpli_flpt_frd_domain,
      lpli_flpt_wrk_refno,lpli_buyer_seller_linked_ind,lpli_authority_ind,lpli_orig_authority_ind,lpli_parh_version) 
     VALUES 
      (l_tmp_par_refno,l_tare_refno,2,'BUYER','LBTT','RETURNPARTYLINKS',1,'N','N','N',l_h_version);

     INSERT INTO parties 
      (par_refno,par_type,par_per_surname,par_per_forename,par_marketing_ind)
     VALUES 
      (par_refno_seq.nextval,'PER','Seller-Second','Disregard','N') 
     RETURNING par_refno INTO l_tmp_par_refno;

     CREATE_OR_MAINTAIN_ADDRESS(P_refno=>l_tmp_par_refno, p_fao_code=>'PAR', P_Adr_address_line_1=>'2232 Path Rd',
      p_adr_address_line_2=>'Garden Village', p_adr_town=>'NORTHTOWN', p_adr_county=>'Northshire', p_adr_postcode=>'RG1 1PB');

     HISTORY_TABLES_API.SNAPSHOT_PARTY(
      p_par_refno=>l_tmp_par_refno,
      p_snapshot_src_vn=>NULL,
      p_parh_version=>l_h_version);

     INSERT INTO lbtt_return_party_links 
      (lpli_par_refno,lpli_lbtt_tare_refno,lpli_lbtt_version,lpli_flpt_type,lpli_flpt_srv_code,lpli_flpt_frd_domain,
      lpli_flpt_wrk_refno,lpli_buyer_seller_linked_ind,lpli_authority_ind,lpli_orig_authority_ind,lpli_parh_version)
     VALUES 
      (l_tmp_par_refno,l_tare_refno,2,'SELLER','LBTT','RETURNPARTYLINKS',1,'N','N','N',l_h_version);

    -- Insert the agent and the link to the account
     HISTORY_TABLES_API.SNAPSHOT_PARTY(
      p_par_refno=>l_par_refno,
      p_snapshot_src_vn=>NULL,
      p_parh_version=>l_h_version);

     INSERT INTO lbtt_return_party_links 
      (lpli_par_refno,lpli_lbtt_tare_refno,lpli_lbtt_version,lpli_flpt_type,lpli_flpt_srv_code,lpli_flpt_frd_domain,
      lpli_flpt_wrk_refno,lpli_buyer_seller_linked_ind,lpli_authority_ind,lpli_orig_authority_ind,lpli_parh_version) 
     VALUES 
      (l_par_refno,l_tare_refno,2,'AGENT','LBTT','RETURNPARTYLINKS',1,'Y','N','N',l_h_version);

    --*********************************
    -- Create the Financial accounts for the PORTAL.ONE account
    --*********************************
    INSERT INTO financial_accounts
      (fiac_refno,fiac_reference,fiac_wrk_refno,fiac_srv_code,fiac_suspense_ind)
    values
      (fiac_seq.nextval,'PORTAL.ONE',1,'LBTT',NULL)
    RETURNING fiac_refno INTO l_fiac_refno;
    
    INSERT INTO fiac_party_links(
    fpli_par_refno,fpli_fiac_refno,
    fpli_ffpl_type,fpli_ffpl_frd_domain,fpli_ffpl_srv_code,fpli_ffpl_wrk_refno,fpli_authority_ind
    ) VALUES (
    l_par_refno,l_fiac_refno,
    'AGENT','FIACPARTYLINKS','LBTT',1,'Y');
    
    INSERT INTO transactions
    (tra_refno,tra_actual_date,tra_effective_date,tra_fiac_refno,
    tra_tty_srv_code,tra_tty_code,tra_tty_wrk_refno,tra_amount,
    tra_related_reference,tra_related_subreference,tra_fobt_frd_domain, tra_fobt_srv_code, tra_fobt_type, tra_fobt_wrk_refno
    ) VALUES (
    tra_seq.nextval,'10-JAN-2019','10-JAN-2019',l_fiac_refno,
    'LBTT','LBRT',1,1000,
    'RS2000001AAAA','1','OBJECT TYPES','LBTT','RETURN',1)
    RETURNING tra_refno INTO l_ltra_refno;
    
    INSERT INTO transactions
    (tra_refno,tra_actual_date,tra_effective_date,tra_fiac_refno,
    tra_tty_srv_code,tra_tty_code,tra_tty_wrk_refno,tra_amount,
    tra_related_reference,tra_related_subreference,tra_fobt_frd_domain, tra_fobt_srv_code, tra_fobt_type, tra_fobt_wrk_refno
    ) VALUES (
    tra_seq.nextval,'11-JAN-2019','11-JAN-2019',l_fiac_refno,
    'LBTT','CHQ',1,-900,
    NULL,NULL,NULL,NULL,NULL,NULL)
    RETURNING tra_refno INTO l_ptra_refno;

    INSERT INTO transaction_matches(  
    tram_automatic_ind,tram_amount,
    tram_credit_tra_refno,tram_debit_tra_refno
    ) VALUES (
    'N',900,
    l_ptra_refno,l_ltra_refno );
    
    INSERT INTO transactions
    (tra_refno,tra_actual_date,tra_effective_date,tra_fiac_refno,
    tra_tty_srv_code,tra_tty_code,tra_tty_wrk_refno,tra_amount,
    tra_related_reference,tra_related_subreference,tra_fobt_frd_domain, tra_fobt_srv_code, tra_fobt_type, tra_fobt_wrk_refno
    ) VALUES (
    tra_seq.nextval,'01-JAN-2019','01-JAN-2019',l_fiac_refno,
    'LBTT','LBT1',1,100,
    'RS2000001AAAA','1','OBJECT TYPES','LBTT','RETURN',1);

    --*********************************
    -- Create the case and messages for the PORTAL.ONE account
    --*********************************
  INSERT INTO cases (
    case_refno,case_reference,
    case_caty_type,case_caty_srv_code,case_caty_wrk_refno,
    case_cast_status,case_casr_reason,case_description,
    case_automatic_ind,case_fcas_source,case_fcas_frd_domain,case_fcas_wrk_refno,case_fcas_srv_code,
    case_receipt_date,case_all_information_date,
    case_fobt_type,case_fobt_frd_domain,case_fobt_wrk_refno,case_fobt_srv_code,case_related_reference
  ) VALUES (
    case_seq.nextval,'PORTAL.RS2000001AAAA',
    'MESSAGE','LBTT',1,
    'OPEN','SECURE MESSAGE RECEIVED','Test Data',
    'Y','DASHBOARD','CASESOURCES',1,'LBTT',
    '01-JAN-2019','01-JAN-2019',
    'RETURN','OBJECT TYPES',1,'LBTT','RS2000001AAAA'
  )
  returning case_refno INTO l_case_refno;
  
  INSERT INTO secure_messages (
    smsg_refno,smsg_original_refno,
    smsg_msgs_subject,smsg_msgs_frd_domain,smsg_msgs_wrk_refno,smsg_msgs_srv_code,
    smsg_title,smsg_body,smsg_case_refno,
    smsg_reference,
    smsg_read_ind,smsg_read_date,smsg_read_by, smsg_par_refno,smsg_direction,
    smsg_created_by,smsg_created_date,smsg_alt_reference
  ) VALUES (
    smsg_seq.nextval,smsg_seq.currval,
    'SMSUBT001','MESSAGE_SUBJECT',1,'SYS',
    'Test Message 1','Body for Test Message 1',l_case_refno,
    'RS2000001AAAA',
    'Y',NULL,NULL,l_par_refno,'I',
    'PORTAL.ONE',TO_DATE('22-MAR-2019'),'PORTAL.ONE'
  )
  RETURNING smsg_refno INTO l_orig_smsg_refno;
  
  UPDATE secure_messages
  SET smsg_created_by = 'PORTAL.ONE',smsg_created_date = TO_DATE('22-MAR-2019 11:13','DD-MON-YYYY HH24:MI')
  WHERE smsg_refno = l_orig_smsg_refno;
  
  -- Insert attachment for the above
  INSERT INTO batches(bat_refno,bat_created_date_time,bat_docs_autoindexed,bat_docs_in_batch,bat_scan_reference)
  VALUES (dip_batch_seq.nextval,TO_DATE('22-MAR-2019 11:13','DD-MON-YYYY HH24:MI'),0,1,'web page created');

  INSERT INTO documents (
      doc_refno,
      doc_dty_code,
      doc_bat_refno,
      doc_batch_seq_number,
      doc_route_status,
      doc_owner,
      doc_ity_code,
      doc_description,
      doc_created_from,
      doc_wrk_refno,
      doc_srv_code,
      doc_direction,
      doc_stored_offline_ind,
      doc_date_created,
      doc_date_received
  ) VALUES (
    dip_document_seq.nextval,
    'ATTACHMENT',
    dip_batch_seq.currval,
    1,
    'IND',
    -1,
    'DOCX',
    'Secure message attachment',
    'SC',
    1,
    'LBTT',
    'I',
    'N',
    TO_DATE('22-MAR-2019 11:13','DD-MON-YYYY HH24:MI'),
    TO_DATE('22-MAR-2019 11:13','DD-MON-YYYY HH24:MI'));

  INSERT INTO external_references
    (ere_doc_refno,ere_est_code,ere_value,ere_created_from,ere_wrk_refno,ere_srv_code)
  VALUES
    (dip_document_seq.currval,'IDOC',dip_document_seq.currval,'S',1,'LBTT');

  -- links to message
  INSERT INTO external_references
   (ere_doc_refno,ere_est_code,ere_value,ere_created_from,ere_wrk_refno,ere_srv_code)
  VALUES
   (dip_document_seq.currval,'SMSG',l_orig_smsg_refno,'S',1,'LBTT');

  -- This document is corrupt but does the job
  INSERT INTO document_pages
  (dpa_doc_refno,dpa_page_number,dpa_image_file,dpa_ity_code,dpa_image)
   values
  (dip_document_seq.currval,1,'test.docx','DOCX',
   fl_utils.base64decode(
   '0M8R4KGxGuEAAAAAAAAAAAAAAAAAAAAAOwADAP7/CQAGAAAAAAAAAAAAAAABQAAAAAAAA=='));
  
  -- next message
  INSERT INTO secure_messages (
    smsg_refno,smsg_original_refno,
    smsg_msgs_subject,smsg_msgs_frd_domain,smsg_msgs_wrk_refno,smsg_msgs_srv_code,
    smsg_title,smsg_body,smsg_case_refno,
    smsg_reference,
    smsg_read_ind,smsg_read_date,smsg_read_by, smsg_par_refno,smsg_direction,
    smsg_created_by,smsg_created_date
  ) VALUES (
    smsg_seq.nextval,l_orig_smsg_refno,
    'SMSUBT001','MESSAGE_SUBJECT',1,'SYS',
    'Test Message 1 - Response','Body for Test Message 1 Response',l_case_refno,
    'RS2000001AAAA',
    'N',NULL,NULL,l_par_refno,'O',
    'ADMIN@RSTU',TO_DATE('22-MAR-2019')
  )
  RETURNING smsg_refno INTO l_smsg_refno;

  UPDATE secure_messages
  SET smsg_created_by = 'ADMIN@RSTU',smsg_created_date = TO_DATE('23-MAR-2019 09:13','DD-MON-YYYY HH24:MI')
  WHERE smsg_refno = l_smsg_refno;
  
  -- below checks for escaping in messages to portal and line feed
  INSERT INTO secure_messages (
    smsg_refno,smsg_original_refno,
    smsg_msgs_subject,smsg_msgs_frd_domain,smsg_msgs_wrk_refno,smsg_msgs_srv_code,
    smsg_title,smsg_body,smsg_case_refno,
    smsg_reference,
    smsg_read_ind,smsg_read_date,smsg_read_by, smsg_par_refno,smsg_direction,
    smsg_created_by,smsg_created_date,smsg_alt_reference
  ) VALUES (
    smsg_seq.nextval,l_orig_smsg_refno,
    'SMSUBT001','MESSAGE_SUBJECT',1,'SYS',
    'Test Message 1 - Reply to Response','<p>Body for Test Message 1</p>
<p>Reply to Response</p>',l_case_refno,
    'RS2000001AAAA',
    'Y',NULL,NULL,l_par_refno,'I',
    'PORTAL.ONE',TO_DATE('22-MAR-2019'),'PORTAL.ONE'
  )
  RETURNING smsg_refno INTO l_smsg_refno;
   
  UPDATE secure_messages
  SET smsg_created_by = 'PORTAL.ONE',smsg_created_date = TO_DATE('23-MAR-2019 15:16','DD-MON-YYYY HH24:MI')
  WHERE smsg_refno = l_smsg_refno;

  INSERT INTO secure_messages (
    smsg_refno,smsg_original_refno,
    smsg_msgs_subject,smsg_msgs_frd_domain,smsg_msgs_wrk_refno,smsg_msgs_srv_code,
    smsg_title,smsg_body,smsg_case_refno,
    smsg_reference,smsg_msgs_subject_desc,
    smsg_read_ind,smsg_read_date,smsg_read_by, smsg_par_refno,smsg_direction,
    smsg_created_by,smsg_created_date,smsg_alt_reference
  ) VALUES (
    smsg_seq.nextval,l_orig_smsg_refno,
    'SMSUBT001','MESSAGE_SUBJECT',1,'SYS',
    'Test Message 2 - Reply to Response','<p>Body for Test Message 2/p>',l_case_refno,
    'RS2000001AAAT','Portal message subject populated',
    'N',NULL,NULL,l_par_refno,'O',
    'PORTAL.ONE',TO_DATE('22-MAR-2019'),NULL
  )
  RETURNING smsg_refno INTO l_smsg_refno;
   
  UPDATE secure_messages
  SET smsg_created_by = 'PORTAL.ONE',smsg_created_date = TO_DATE('23-MAR-2019 15:17','DD-MON-YYYY HH24:MI')
  WHERE smsg_refno = l_smsg_refno;

  INSERT INTO secure_messages (
    smsg_refno,smsg_original_refno,
    smsg_msgs_subject,smsg_msgs_frd_domain,smsg_msgs_wrk_refno,smsg_msgs_srv_code,
    smsg_title,smsg_body,smsg_case_refno,
    smsg_reference,
    smsg_read_ind,smsg_read_date,smsg_read_by, smsg_par_refno,smsg_direction,
    smsg_created_by,smsg_created_date,smsg_alt_reference
  ) VALUES (
    smsg_seq.nextval,l_orig_smsg_refno,
    'SMSUBT001','MESSAGE_SUBJECT',1,'SYS',
    'Test Message 3 - Reply to Response','<p>Body for Test Message 3/p>',l_case_refno,
    'RS2000001AAAT',
    'N',NULL,NULL,l_par_refno,'O',
    'PORTAL.ONE',TO_DATE('22-MAR-2019'),'Agent Ref 554'
  )
  RETURNING smsg_refno INTO l_smsg_refno;
   
  UPDATE secure_messages
  SET smsg_created_by = 'PORTAL.ONE',smsg_created_date = TO_DATE('23-MAR-2019 15:18','DD-MON-YYYY HH24:MI')
  WHERE smsg_refno = l_smsg_refno; 
  
  INSERT INTO secure_messages (
    smsg_refno,smsg_original_refno,
    smsg_msgs_subject,smsg_msgs_frd_domain,smsg_msgs_wrk_refno,smsg_msgs_srv_code,
    smsg_title,smsg_body,smsg_case_refno,
    smsg_reference,
    smsg_read_ind,smsg_read_date,smsg_read_by, smsg_par_refno,smsg_direction,
    smsg_created_by,smsg_created_date,smsg_alt_reference,
    smsg_recalled_ind, smsg_recalled_by, smsg_recalled_date
  ) VALUES (
    smsg_seq.nextval,l_orig_smsg_refno,
    'SMSUBT001','MESSAGE_SUBJECT',1,'SYS',
    'Recalled message','Recalled message body',l_case_refno,
    'RS2000001AAAT',
    'N',NULL,NULL,l_par_refno,'O',
    'PORTAL.ONE',TO_DATE('22-MAR-2019'),'PORTAL.ONE',
    'Y','PORTAL.TWO', TO_DATE('30-MAR-2024')
  )
  RETURNING smsg_refno INTO l_smsg_refno;
   
  UPDATE secure_messages
  SET smsg_created_by = 'PORTAL.ONE',smsg_created_date = TO_DATE('23-MAR-2019 15:16','DD-MON-YYYY HH24:MI')
  WHERE smsg_refno = l_smsg_refno;

  INSERT INTO secure_messages (
    smsg_refno,smsg_original_refno,
    smsg_msgs_subject,smsg_msgs_frd_domain,smsg_msgs_wrk_refno,smsg_msgs_srv_code,
    smsg_title,smsg_body,smsg_case_refno,
    smsg_reference,
    smsg_read_ind,smsg_read_date,smsg_read_by, smsg_par_refno,smsg_direction,
    smsg_created_by,smsg_created_date,smsg_alt_reference
  ) VALUES (
    smsg_seq.nextval,l_orig_smsg_refno,
    'SMSUBT001','MESSAGE_SUBJECT',1,'SYS',
    'Test Message 4','<p>Body for Test Message 4/p>',l_case_refno,
    NULL,
    'N',NULL,NULL,l_par_refno,'O',
    'PORTAL.ONE',TO_DATE('22-MAR-2019'),'Agent Only Ref'
  )
  RETURNING smsg_refno INTO l_smsg_refno;
   
  UPDATE secure_messages
  SET smsg_created_by = 'PORTAL.ONE',smsg_created_date = TO_DATE('25-MAR-2019 16:16','DD-MON-YYYY HH24:MI')
  WHERE smsg_refno = l_smsg_refno;
  -- ********************************
  -- Create the Account for new users
  INSERT INTO parties
    (par_refno,par_type,par_com_company_name,par_org_name,par_marketing_ind,par_fact_type,par_fact_frd_domain,par_fact_srv_code,par_fact_wrk_refno)
  VALUES
    (par_refno_seq.nextval,'ORG','Test Portal Company New Users','Test Portal Company New Users','N','AGENT','PARTY_ACT_TYPES','SYS',1)
  RETURNING par_refno INTO l_par_refno;
  
  create_or_maintain_cde(p_par_refno=>l_par_refno,p_cde_cme_code=>'EMAIL',p_value=>'noreply@necsws.com');
  create_or_maintain_cde(p_par_refno=>l_par_refno,p_cde_cme_code=>'PHONE',p_value=>'07700900321');
  create_or_maintain_address(p_refno=>l_par_refno,p_fao_code=>'PAR',p_adr_address_line_1=>'2 Park Lane',p_adr_address_line_2=>'Garden Village',p_adr_town=>'NORTHTOWN',p_adr_county=>'Northshire',p_adr_postcode=>'RG1 1PB');

  -- Needed for FOPS will not be needed for revs scot
--  INSERT INTO fops_account
--     (fac_wrk_refno,fac_par_refno,fac_current_ind)
--  VALUES
--     (3,l_par_refno,'Y');
        
  -- Note password is created by hashing the username and the password
  INSERT INTO users
     (usr_username,usr_password,usr_password_change_date,usr_force_pw_change,usr_current_ind,usr_name,usr_email_address,usr_wrk_refno,
      usr_int_user_ind,usr_par_refno,usr_per_forename,usr_per_surname,usr_pref_nld_code,usr_tac_signed_date)
  VALUES
     ('PORTAL.NEW.USERS',UPPER (dbms_obfuscation_toolkit.md5 (input => utl_i18n.string_to_raw('PORTAL.NEW.USERS'||'Password1!'))),TRUNC(SYSDATE),'N','Y','Portal New Users','noreply@necsws.com',3,
      'N',l_par_Refno,'Portal User','New Users','ENG',TRUNC(SYSDATE));
      
  INSERT INTO role_users
    (rus_rol_code,rus_usr_username)
  (SELECT rus_rol_code,'PORTAL.NEW.USERS'
    FROM role_users
   WHERE rus_usr_username = 'TEMPLATE_SELFSRV_USER');
   
   INSERT INTO user_services
    (use_username, use_service)
   VALUES
    ('PORTAL.NEW.USERS','LBTT');
    
   INSERT INTO dd_instructions (
    din_refno,din_par_refno,din_start_date,
    din_bank_sort_code,din_bank_account_number,din_bank_bsoc_roll_number,
    din_first_dd_taken_ind,din_auddis_code,din_auddis_trans_date,din_bank_account_name,
    din_mandate_reference
    ) VALUES (
    din_seq.nextval,l_par_refno,TO_DATE('01-JAN-2019','DD-MON-YYYY'),
    '00-00-00','12345678','0',
    'N','NP',TO_DATE('01-JAN-2019','DD-MON-YYYY'),'Portal Test','RS1234');
      

  -- ********************************
  -- Create the Account for the person
  INSERT INTO parties
    (par_refno,par_type,par_per_surname,par_per_forename,par_marketing_ind,par_fact_type,par_fact_frd_domain,par_fact_srv_code,par_fact_wrk_refno)
  VALUES
    (par_refno_seq.nextval,'PER','Portal-Test','Adam','N','TAXPAYER','PARTY_ACT_TYPES','SYS',1)
  RETURNING par_refno INTO l_par_refno;
  
  create_or_maintain_cde(p_par_refno=>l_par_refno,p_cde_cme_code=>'EMAIL',p_value=>'noreply@necsws.com');
  create_or_maintain_cde(p_par_refno=>l_par_refno,p_cde_cme_code=>'PHONE',p_value=>'07700900321');
  create_or_maintain_address(p_refno=>l_par_refno,p_fao_code=>'PAR',p_adr_address_line_1=>'3 Park Lane',p_adr_address_line_2=>'Garden Village',p_adr_town=>'NORTHTOWN',p_adr_county=>'Northshire',p_adr_postcode=>'RG1 1PB');

  -- Needed for FOPS will not be needed for revs scot
--  INSERT INTO fops_account
--     (fac_wrk_refno,fac_par_refno,fac_current_ind)
--  VALUES
--     (3,l_par_refno,'Y');
        
  -- Note password is created by hashing the username and the password
  INSERT INTO users
     (usr_username,usr_password,usr_password_change_date,usr_force_pw_change,usr_current_ind,usr_name,usr_email_address,usr_wrk_refno,
      usr_int_user_ind,usr_par_refno,usr_per_forename,usr_per_surname,usr_pref_nld_code,usr_tac_signed_date)
  VALUES
     ('ADAM.PORTAL-TEST',UPPER (dbms_obfuscation_toolkit.md5 (input => utl_i18n.string_to_raw('ADAM.PORTAL-TEST'||'Password1!'))),TRUNC(SYSDATE),'N','Y','Adam Portal-Test','noreply@necsws.com',3,
      'N',l_par_Refno,'Adam','Portal-Test','ENG',TRUNC(SYSDATE));
      
  INSERT INTO role_users
    (rus_rol_code,rus_usr_username)
  (SELECT rus_rol_code,'ADAM.PORTAL-TEST'
    FROM role_users
   WHERE rus_usr_username = 'TEMPLATE_SELFSRV_USER');
   
   INSERT INTO user_services
    (use_username, use_service)
   VALUES
    ('ADAM.PORTAL-TEST','LBTT');   

  -- ********************************
  -- Create the Account for registered company
  INSERT INTO parties
    (par_refno,par_type,par_com_company_name,par_org_name,par_com_regno,par_marketing_ind,par_fact_type,par_fact_frd_domain,par_fact_srv_code,par_fact_wrk_refno)
  VALUES
    (par_refno_seq.nextval,'ORG','NORTHGATE PUBLIC SERVICES LIMITED','NORTHGATE PUBLIC SERVICES LIMITED','09338960','N','TAXPAYER','PARTY_ACT_TYPES','SYS',1)
  RETURNING par_refno INTO l_par_refno;
  
  create_or_maintain_address(p_refno=>l_par_refno,p_fao_code=>'PAR',p_adr_address_line_1=>'1st Floor, Imex Centre',p_adr_address_line_2=>'575-599 Maxted Road',p_adr_town=>'Hemel Hempstead',p_adr_county=>'Hertfordshire',p_adr_postcode=>'HP2 7DX');
  create_or_maintain_address(p_refno=>l_par_refno,p_fao_code=>'PAR',p_adr_address_line_1=>'1st Floor, Imex Centre',p_adr_address_line_2=>'575-599 Maxted Road',p_adr_town=>'Hemel Hempstead',p_adr_county=>'Hertfordshire',p_adr_postcode=>'HP2 7DX',p_adr_type=>'REGISTERED');

  -- Needed for FOPS will not be needed for revs scot
--  INSERT INTO fops_account
--     (fac_wrk_refno,fac_par_refno,fac_current_ind)
--  VALUES
--     (3,l_par_refno,'Y');
        
  -- Note password is created by hashing the username and the password
  INSERT INTO users
     (usr_username,usr_password,usr_password_change_date,usr_force_pw_change,usr_current_ind,usr_name,usr_email_address,usr_wrk_refno,
      usr_int_user_ind,usr_par_refno,usr_per_forename,usr_per_surname,usr_pref_nld_code,usr_tac_signed_date)
  VALUES
     ('PORTAL.NORTHGATE',UPPER (dbms_obfuscation_toolkit.md5 (input => utl_i18n.string_to_raw('PORTAL.NORTHGATE'||'Password1!'))),TRUNC(SYSDATE),'N','Y','Portal Northgate','noreply@necsws.com',3,
      'N',l_par_Refno,'Portal','Northgate','ENG',TRUNC(SYSDATE));
      
  INSERT INTO role_users
    (rus_rol_code,rus_usr_username)
  (SELECT rus_rol_code,'PORTAL.NORTHGATE'
    FROM role_users
   WHERE rus_usr_username = 'TEMPLATE_SELFSRV_USER');
   
   INSERT INTO user_services
    (use_username, use_service)
   VALUES
    ('PORTAL.NORTHGATE','LBTT');
    
  -- ********************************
  -- Create the Account which has no services yet
  INSERT INTO parties
    (par_refno,par_type,par_com_company_name,par_org_name,par_marketing_ind,par_fact_type,par_fact_frd_domain,par_fact_srv_code,par_fact_wrk_refno)
  VALUES
    (par_refno_seq.nextval,'ORG','Test Portal Company No Services','Test Portal Company No Services','N','AGENT','PARTY_ACT_TYPES','SYS',1)
  RETURNING par_refno INTO l_par_refno;
  
  create_or_maintain_cde(p_par_refno=>l_par_refno,p_cde_cme_code=>'EMAIL',p_value=>'noreply@necsws.com');
  create_or_maintain_cde(p_par_refno=>l_par_refno,p_cde_cme_code=>'PHONE',p_value=>'07800800321');
  create_or_maintain_address(p_refno=>l_par_refno,p_fao_code=>'PAR',p_adr_address_line_1=>'2 Green Lane',p_adr_address_line_2=>'Wood Village',p_adr_town=>'NORTHTOWN',p_adr_county=>'Northshire',p_adr_postcode=>'RG7 1FG');

  -- Note password is created by hashing the username and the password
  INSERT INTO users
     (usr_username,usr_password,usr_password_change_date,usr_force_pw_change,usr_current_ind,usr_name,usr_email_address,usr_wrk_refno,
      usr_int_user_ind,usr_par_refno,usr_per_forename,usr_per_surname,usr_pref_nld_code,usr_tac_signed_date)
  VALUES
     ('PORTAL.NO.SERVICES',UPPER (dbms_obfuscation_toolkit.md5 (input => utl_i18n.string_to_raw('PORTAL.NO.SERVICES'||'Password1!'))),TRUNC(SYSDATE),'N','Y','Portal No Services','noreply@necsws.com',3,
      'N',l_par_Refno,'Portal','Northgate','ENG',TRUNC(SYSDATE));
      
  INSERT INTO role_users
    (rus_rol_code,rus_usr_username)
  (SELECT rus_rol_code,'PORTAL.NO.SERVICES'
    FROM role_users
   WHERE rus_usr_username = 'TEMPLATE_SELFSRV_USER');
	
 
  -- ********************************
  -- Create the Account for Waste Operator with two sites with pre-seeded data
  
  -- we need to hardcode the lasi_refno so make sure we have space by rolling onto at least 101 in sequence
  
  while l_last_refno < 100
  loop
      SELECT lasi_seq.nextval
      INTO l_last_refno
      FROM dual;
      dbms_output.put_line('Number: '||l_last_refno);
  end loop;
  
  INSERT INTO parties
    (par_refno,par_type,par_com_company_name,par_org_name,par_com_regno,par_marketing_ind,par_fact_type,par_fact_frd_domain,par_fact_srv_code,par_fact_wrk_refno)
  VALUES
    (par_refno_seq.nextval,'ORG','Test Portal Company Waste','Test Portal Company Waste',NULL,'N','TAXPAYER','PARTY_ACT_TYPES','SYS',1)
  RETURNING par_refno INTO l_par_refno;

  INSERT INTO alternate_references
    (alre_object_reference,alre_alrt_object_type,alre_alrt_type,alre_alrt_srv_code,alre_reference)
  VALUES
    (l_par_refno,'PAR','REGISTRATION_REFERENCE','SYS','SLFT-LO-00001');
  
  create_or_maintain_address(p_refno=>l_par_refno,p_fao_code=>'PAR',p_adr_address_line_1=>'The landfill site',p_adr_address_line_2=>'Some Village',p_adr_town=>'Some Town',p_adr_county=>'Northshire',p_adr_postcode=>'NP7 8LB');

  history_tables_api.snapshot_party( p_par_refno=>l_par_refno,p_snapshot_src_vn=>NULL,p_parh_version=>l_h_version);

  -- Needed for FOPS will not be needed for revs scot
--  INSERT INTO fops_account
--     (fac_wrk_refno,fac_par_refno,fac_current_ind)
--  VALUES
--     (3,l_par_refno,'Y');
        
  -- Note password is created by hashing the username and the password
  INSERT INTO users
     (usr_username,usr_password,usr_password_change_date,usr_force_pw_change,usr_current_ind,usr_name,usr_email_address,usr_wrk_refno,
      usr_int_user_ind,usr_par_refno,usr_per_forename,usr_per_surname,usr_pref_nld_code,usr_tac_signed_date)
  VALUES
     ('PORTAL.WASTE',UPPER (dbms_obfuscation_toolkit.md5 (input => utl_i18n.string_to_raw('PORTAL.WASTE'||'Password1!'))),TRUNC(SYSDATE),'N','Y','Portal Waste','noreply@necsws.com',3,
      'N',l_par_Refno,'Portal','Waste','ENG',TRUNC(SYSDATE));
      
  INSERT INTO role_users
    (rus_rol_code,rus_usr_username)
  (SELECT rus_rol_code,'PORTAL.WASTE'
    FROM role_users
   WHERE rus_usr_username = 'TEMPLATE_SELFSRV_USER');
   
   INSERT INTO user_services
    (use_username, use_service)
   VALUES
    ('PORTAL.WASTE','SLFT');  
   
  --- Insert the site address
  INSERT INTO addresses
     (adr_refno,adr_address_line_1,adr_address_line_2,adr_town,adr_postcode,adr_county,adr_country)
  VALUES
     (adr_seq.nextval,'The Small Hole',NULL,'Northtown','NP7 8LB',NULL,'GB')
  RETURNING adr_refno INTO l_adr_refno;
  
  INSERT INTO landfill_sites
    (lasi_refno, lasi_version, lasi_par_refno, lasi_start_date, lasi_sepa_licence_number,lasi_site_name,lasi_lower_expected_tonnage,lasi_standard_expected_tonnage,lasi_exempt_expected_tonnage,
     lasi_weighbridge_ind,lasi_non_disposal_ind,lasi_controller_par_refno, lasi_adr_refno)
   VALUES
    (99, 1, l_par_refno, '01-APR-2015', 'SLFT-SITE-00001','Waste Site 1',10000,20000,100,
     'Y','N',l_par_refno, l_adr_refno);
     
  --- Insert the site address
  INSERT INTO addresses
     (adr_refno,adr_address_line_1,adr_address_line_2,adr_town,adr_postcode,adr_county,adr_country)
  VALUES
     (adr_seq.nextval,'The Tiny Hole',NULL,'Northtown','NP7 8LB',NULL,'GB')
  RETURNING adr_refno INTO l_adr_refno;
  
  INSERT INTO landfill_sites
    (lasi_refno, lasi_version, lasi_par_refno, lasi_start_date, lasi_sepa_licence_number,lasi_site_name,lasi_lower_expected_tonnage,lasi_standard_expected_tonnage,lasi_exempt_expected_tonnage,
     lasi_weighbridge_ind,lasi_non_disposal_ind,lasi_controller_par_refno, lasi_adr_refno)
   VALUES
    (100, 1, l_par_refno, '01-APR-2015', 'SLFT-SITE-00002','Waste Site 2',15000,25000,150,
     'Y','N',l_par_refno, l_adr_refno);
    
  INSERT INTO tax_returns
   (tare_refno, tare_reference, tare_srv_code)
  VALUES
   (tare_seq.nextval,'RS100001AAAAA','SLFT')
  returning tare_refno INTO l_tare_refno;
     
  INSERT INTO slft_returns
    (slft_tare_refno,slft_version,slft_par_refno,slft_parh_version,slft_latest_draft_ind,slft_year,slft_fape_period,slft_fape_frd_domain,slft_fape_srv_code,slft_fape_wrk_refno,
     slft_slcf_contribution,slft_slcf_credit_claimed, slft_total_tax_due, slft_bad_debt_credit, slft_removal_credit, slft_total_credits,
     slft_non_disposal_add_ind, slft_non_disposal_add_text,  slft_non_disposal_delete_ind, slft_non_disposal_delete_text, 
     slft_tax_payable, slft_fpay_method,slft_fpay_frd_domain,slft_fpay_srv_code,slft_fpay_wrk_refno,slft_source, slft_submitted_date)
  VALUES
    (l_tare_refno,1,l_par_refno,l_h_version,'',2018,'Q1','PERIOD','SYS',1,
     10000,8000, 234000, 20, 50, 8070,
     'N', '',  'N','', 
     225840, 'BACS','PAYMENT TYPE','SLFT',1,'P', SLFT_SUBMITTED_DATE);

  INSERT INTO slft_returns
    (slft_tare_refno,slft_version,slft_par_refno,slft_parh_version,slft_latest_draft_ind,slft_year,slft_fape_period,slft_fape_frd_domain,slft_fape_srv_code,slft_fape_wrk_refno,
     slft_slcf_contribution,slft_slcf_credit_claimed, slft_total_tax_due, slft_bad_debt_credit, slft_removal_credit, slft_total_credits,
     slft_non_disposal_add_ind, slft_non_disposal_add_text,  slft_non_disposal_delete_ind, slft_non_disposal_delete_text, 
     slft_tax_payable, slft_fpay_method,slft_fpay_frd_domain,slft_fpay_srv_code,slft_fpay_wrk_refno,slft_source, slft_submitted_date)
  VALUES
    (l_tare_refno,2,l_par_refno,l_h_version,'L',SLFT_AMENDABLE_YEAR,'Q1','PERIOD','SYS',1,
     10000,8000, 234000, 200, 500, 8700,
     'N', '',  'N','', 
     225300, 'BACS','PAYMENT TYPE','SLFT',1,'P', AMENDABLE_DATE);

-- Single add     
  INSERT INTO tax_returns
   (tare_refno, tare_reference, tare_srv_code)
  VALUES
   (tare_seq.nextval,'RS100002AAAAA','SLFT')
  returning tare_refno INTO l_tare_refno;
     
  INSERT INTO slft_returns
    (slft_tare_refno,slft_version,slft_par_refno,slft_parh_version,slft_latest_draft_ind,slft_year,slft_fape_period,slft_fape_frd_domain,slft_fape_srv_code,slft_fape_wrk_refno,
     slft_slcf_contribution,slft_slcf_credit_claimed, slft_total_tax_due, slft_bad_debt_credit, slft_removal_credit, slft_total_credits,
     slft_non_disposal_add_ind, slft_non_disposal_add_text,  slft_non_disposal_delete_ind, slft_non_disposal_delete_text, 
     slft_tax_payable, slft_fpay_method,slft_fpay_frd_domain,slft_fpay_srv_code,slft_fpay_wrk_refno,slft_source, slft_submitted_date)
  VALUES
    (l_tare_refno,1,l_par_refno,l_h_version,'D',SLFT_AMENDABLE_YEAR,'Q2','PERIOD','SYS',1,
     0,0, 255000, 0, 0, 0,
     'N', '',  'N','', 
     255000,'BACS','PAYMENT TYPE','SLFT',1,'P', NULL);
	 
-- Ez added test data
  INSERT INTO tax_returns
   (tare_refno, tare_reference, tare_srv_code)
  VALUES
   (tare_seq.nextval,'RS1008001HALO','SLFT')
  returning tare_refno INTO l_tare_refno;
     
  INSERT INTO slft_returns
    (slft_tare_refno,slft_version,slft_par_refno,slft_parh_version,slft_latest_draft_ind,slft_year,slft_fape_period,slft_fape_frd_domain,slft_fape_srv_code,slft_fape_wrk_refno,
     slft_slcf_contribution,slft_slcf_credit_claimed, slft_total_tax_due, slft_bad_debt_credit, slft_removal_credit, slft_total_credits,
     slft_non_disposal_add_ind, slft_non_disposal_add_text,  slft_non_disposal_delete_ind, slft_non_disposal_delete_text, 
     slft_tax_payable, slft_fpay_method,slft_fpay_frd_domain,slft_fpay_srv_code,slft_fpay_wrk_refno,slft_source, slft_submitted_date)
  VALUES
    (l_tare_refno,1,l_par_refno,l_h_version,'',2017,'Q1','PERIOD','SYS',1,
     11520,4580, 762000, 1350, 1420, 9000,
     'N', '',  'N','', 
     255000,'BACS','PAYMENT TYPE','SLFT',1,'P', SLFT_SUBMITTED_DATE);
	 
  INSERT INTO slft_returns
    (slft_tare_refno,slft_version,slft_par_refno,slft_parh_version,slft_latest_draft_ind,slft_year,slft_fape_period,slft_fape_frd_domain,slft_fape_srv_code,slft_fape_wrk_refno,
     slft_slcf_contribution,slft_slcf_credit_claimed, slft_total_tax_due, slft_bad_debt_credit, slft_removal_credit, slft_total_credits,
     slft_non_disposal_add_ind, slft_non_disposal_add_text,  slft_non_disposal_delete_ind, slft_non_disposal_delete_text, 
     slft_tax_payable, slft_fpay_method,slft_fpay_frd_domain,slft_fpay_srv_code,slft_fpay_wrk_refno,slft_source, slft_submitted_date)
  VALUES
    (l_tare_refno,2,l_par_refno,l_h_version,'L',2016,'Q1','PERIOD','SYS',1,
     11520,4580, 762000, 1900, 1440, 9000,
     'N', '',  'N','', 
     255000,'BACS','PAYMENT TYPE','SLFT',1,'P', AMENDABLE_DATE);
	 
  INSERT INTO tax_returns
   (tare_refno, tare_reference, tare_srv_code)
  VALUES
   (tare_seq.nextval,'RS1008002WAUW','SLFT')
  returning tare_refno INTO l_tare_refno;
     
  INSERT INTO slft_returns
    (slft_tare_refno,slft_version,slft_par_refno,slft_parh_version,slft_latest_draft_ind,slft_year,slft_fape_period,slft_fape_frd_domain,slft_fape_srv_code,slft_fape_wrk_refno,
     slft_slcf_contribution,slft_slcf_credit_claimed, slft_total_tax_due, slft_bad_debt_credit, slft_removal_credit, slft_total_credits,
     slft_non_disposal_add_ind, slft_non_disposal_add_text,  slft_non_disposal_delete_ind, slft_non_disposal_delete_text, 
     slft_tax_payable, slft_fpay_method,slft_fpay_frd_domain,slft_fpay_srv_code,slft_fpay_wrk_refno,slft_source, slft_submitted_date)
  VALUES
    (l_tare_refno,1,l_par_refno,l_h_version,'D',2019,'Q4','PERIOD','SYS',1,
     10,10, 255000, 110, 0, 0,
     'N', '',  'N','', 
     255000,'BACS','PAYMENT TYPE','SLFT',1,'P', NULL);
  
  INSERT INTO tax_returns
   (tare_refno, tare_reference, tare_srv_code)
  VALUES
   (tare_seq.nextval,'RS1008003OKAY','SLFT')
  returning tare_refno INTO l_tare_refno;
     
  INSERT INTO slft_returns
    (slft_tare_refno,slft_version,slft_par_refno,slft_parh_version,slft_latest_draft_ind,slft_year,slft_fape_period,slft_fape_frd_domain,slft_fape_srv_code,slft_fape_wrk_refno,
     slft_slcf_contribution,slft_slcf_credit_claimed, slft_total_tax_due, slft_bad_debt_credit, slft_removal_credit, slft_total_credits,
     slft_non_disposal_add_ind, slft_non_disposal_add_text,  slft_non_disposal_delete_ind, slft_non_disposal_delete_text, 
     slft_tax_payable, slft_fpay_method,slft_fpay_frd_domain,slft_fpay_srv_code,slft_fpay_wrk_refno,slft_source, slft_submitted_date)
  VALUES
    (l_tare_refno,1,l_par_refno,l_h_version,'',2019,'Q3','PERIOD','SYS',1,
     4500,3220, 55000, 30, 20, 1650,
     'N', '',  'N','', 
     255000,'BACS','PAYMENT TYPE','SLFT',1,'P', SLFT_SUBMITTED_DATE);
	 
  INSERT INTO slft_returns
    (slft_tare_refno,slft_version,slft_par_refno,slft_parh_version,slft_latest_draft_ind,slft_year,slft_fape_period,slft_fape_frd_domain,slft_fape_srv_code,slft_fape_wrk_refno,
     slft_slcf_contribution,slft_slcf_credit_claimed, slft_total_tax_due, slft_bad_debt_credit, slft_removal_credit, slft_total_credits,
     slft_non_disposal_add_ind, slft_non_disposal_add_text,  slft_non_disposal_delete_ind, slft_non_disposal_delete_text, 
     slft_tax_payable, slft_fpay_method,slft_fpay_frd_domain,slft_fpay_srv_code,slft_fpay_wrk_refno,slft_source, slft_submitted_date)
  VALUES
    (l_tare_refno,2,l_par_refno,l_h_version,'L',2019,'Q3','PERIOD','SYS',1,
     4500,3220, 55000, 120, 130, 1650,
     'N', '',  'N','', 
     255000,'BACS','PAYMENT TYPE','SLFT',1,'P', AMENDABLE_DATE);
	 
  INSERT INTO slft_returns
    (slft_tare_refno,slft_version,slft_par_refno,slft_parh_version,slft_latest_draft_ind,slft_year,slft_fape_period,slft_fape_frd_domain,slft_fape_srv_code,slft_fape_wrk_refno,
     slft_slcf_contribution,slft_slcf_credit_claimed, slft_total_tax_due, slft_bad_debt_credit, slft_removal_credit, slft_total_credits,
     slft_non_disposal_add_ind, slft_non_disposal_add_text,  slft_non_disposal_delete_ind, slft_non_disposal_delete_text, 
     slft_tax_payable, slft_fpay_method,slft_fpay_frd_domain,slft_fpay_srv_code,slft_fpay_wrk_refno,slft_source, slft_submitted_date)
  VALUES
    (l_tare_refno,3,l_par_refno,l_h_version,'D',2019,'Q3','PERIOD','SYS',1,
     4500,3220, 55000, 340, 440, 1650,
     'N', '',  'N','', 
     255000,'BACS','PAYMENT TYPE','SLFT',1,'P', NULL);

  -- Insert Open Enquiry Case
  INSERT INTO cases (
    case_refno, case_reference,
    case_caty_type, case_caty_srv_code, case_caty_wrk_refno,
    case_cast_status, case_casr_reason,
    case_description,
    case_automatic_ind, case_fcas_source, case_fcas_frd_domain, case_fcas_wrk_refno, case_fcas_srv_code,
    case_receipt_date, case_all_information_date, case_due_date,
    case_fobt_type, case_fobt_frd_domain, case_fobt_wrk_refno, case_fobt_srv_code, case_related_reference,
    case_fiac_refno
  ) VALUES (
    case_seq.nextval, 'PORTAL.CMS1008003O',
    'ENQUIRY', 'SLFT', 1,
    'OPEN', 'ENQUIRYTO PROCESS',
    'Test case for Portal',
    'N', 'EMAIL', 'CASESOURCES', 1, 'SLFT',
    TO_DATE('01-JUN-2019','DD-MON-YYYY'), TO_DATE('01-JUN-2019','DD-MON-YYYY'), TO_DATE('01-AUG-2019','DD-MON-YYYY'), 
    'RETURN', 'CASEOBJECTTYPES', 1,'SLFT', 'RS1008003OKAY',
    NULL);
  
  INSERT INTO tax_returns
   (tare_refno, tare_reference, tare_srv_code)
  VALUES
   (tare_seq.nextval,'RS1008004HMMM','SLFT')
  returning tare_refno INTO l_tare_refno;
     
  INSERT INTO slft_returns
    (slft_tare_refno,slft_version,slft_par_refno,slft_parh_version,slft_latest_draft_ind,slft_year,slft_fape_period,slft_fape_frd_domain,slft_fape_srv_code,slft_fape_wrk_refno,
     slft_slcf_contribution,slft_slcf_credit_claimed, slft_total_tax_due, slft_bad_debt_credit, slft_removal_credit, slft_total_credits,
     slft_non_disposal_add_ind, slft_non_disposal_add_text,  slft_non_disposal_delete_ind, slft_non_disposal_delete_text, 
     slft_tax_payable, slft_fpay_method,slft_fpay_frd_domain,slft_fpay_srv_code,slft_fpay_wrk_refno,slft_source, slft_submitted_date)
  VALUES
    (l_tare_refno,1,l_par_refno,l_h_version,'L',2019,'Q2','PERIOD','SYS',1,
     0,0, 445000, 0, 0, 0,
     'N', '',  'N','', 
     255000,'BACS','PAYMENT TYPE','SLFT',1,'P', SLFT_SUBMITTED_DATE);
     
    --*********************************
    -- Create the Financial accounts for the PORTAL.WASTE account
    --*********************************
    INSERT INTO financial_accounts
      (fiac_refno,fiac_reference,fiac_wrk_refno,fiac_srv_code,fiac_suspense_ind)
    values
      (fiac_seq.nextval,'PORTAL.WASTE',1,'SLFT',NULL)
    RETURNING fiac_refno INTO l_fiac_refno;
    
    INSERT INTO fiac_party_links(
    fpli_par_refno,fpli_fiac_refno,
    fpli_ffpl_type,fpli_ffpl_frd_domain,fpli_ffpl_srv_code,fpli_ffpl_wrk_refno,fpli_authority_ind
    ) VALUES (
    l_par_refno,l_fiac_refno,
    'LIABLE','FIACPARTYLINKS','SLFT',1,'Y');
    
    INSERT INTO transactions
    (tra_refno,tra_actual_date,tra_effective_date,tra_fiac_refno,
    tra_tty_srv_code,tra_tty_code,tra_tty_wrk_refno,tra_amount,
    tra_related_reference,tra_related_subreference,tra_fobt_frd_domain, tra_fobt_srv_code, tra_fobt_type, tra_fobt_wrk_refno
    ) VALUES (
    tra_seq.nextval,'10-JAN-2019','10-JAN-2019',l_fiac_refno,
    'SLFT','SLFT',1,1000,
    'RS100001AAAAA','1','OBJECT TYPES','SLFT','RETURN',1)
    RETURNING tra_refno INTO l_ltra_refno;
    
 
-- ********************************
  -- Create the Account for Waste Operator with two sites with for adding new returns
  
  -- we need to hardcode the lasi_refno so make sure we have space by rolling onto at least 101 in sequence
   
  INSERT INTO parties
    (par_refno,par_type,par_com_company_name,par_org_name,par_com_regno,par_marketing_ind,par_fact_type,par_fact_frd_domain,par_fact_srv_code,par_fact_wrk_refno)
  VALUES
    (par_refno_seq.nextval,'ORG','Test Portal Company Waste New Returns','Test Portal Company Waste New Returns',NULL,'N','TAXPAYER','PARTY_ACT_TYPES','SYS',1)
  RETURNING par_refno INTO l_par_refno;

  INSERT INTO alternate_references
    (alre_object_reference,alre_alrt_object_type,alre_alrt_type,alre_alrt_srv_code,alre_reference)
  VALUES
    (l_par_refno,'PAR','REGISTRATION_REFERENCE','SYS','SLFT-LO-00002');
    
  create_or_maintain_address(p_refno=>l_par_refno,p_fao_code=>'PAR',p_adr_address_line_1=>'The landfill site',p_adr_address_line_2=>'Some Village',p_adr_town=>'Some Town',p_adr_county=>'Northshire',p_adr_postcode=>'NP7 8LB');

  -- Needed for FOPS will not be needed for revs scot
--  INSERT INTO fops_account
--     (fac_wrk_refno,fac_par_refno,fac_current_ind)
--  VALUES
--     (3,l_par_refno,'Y');
        
  -- Note password is created by hashing the username and the password
  INSERT INTO users
     (usr_username,usr_password,usr_password_change_date,usr_force_pw_change,usr_current_ind,usr_name,usr_email_address,usr_wrk_refno,
      usr_int_user_ind,usr_par_refno,usr_per_forename,usr_per_surname,usr_pref_nld_code,usr_tac_signed_date)
  VALUES
     ('PORTAL.WASTE.NEW',UPPER (dbms_obfuscation_toolkit.md5 (input => utl_i18n.string_to_raw('PORTAL.WASTE.NEW'||'Password1!'))),TRUNC(SYSDATE),'N','Y','Portal Waste New','noreply@necsws.com',3,
      'N',l_par_Refno,'Portal','Waste New','ENG',TRUNC(SYSDATE));
      
  INSERT INTO role_users
    (rus_rol_code,rus_usr_username)
  (SELECT rus_rol_code,'PORTAL.WASTE.NEW'
    FROM role_users
   WHERE rus_usr_username = 'TEMPLATE_SELFSRV_USER');
   
   INSERT INTO user_services
    (use_username, use_service)
   VALUES
    ('PORTAL.WASTE.NEW','SLFT');  
   
  --- Insert the site address
  INSERT INTO addresses
     (adr_refno,adr_address_line_1,adr_address_line_2,adr_town,adr_postcode,adr_county,adr_country)
  VALUES
     (adr_seq.nextval,'The Big Hole',NULL,'Northtown','NP7 8LB',NULL,'GB')
  RETURNING adr_refno INTO l_adr_refno;
  
  INSERT INTO landfill_sites
    (lasi_refno, lasi_version, lasi_par_refno, lasi_start_date, lasi_sepa_licence_number,lasi_site_name,lasi_lower_expected_tonnage,lasi_standard_expected_tonnage,lasi_exempt_expected_tonnage,
     lasi_weighbridge_ind,lasi_non_disposal_ind,lasi_controller_par_refno, lasi_adr_refno)
   VALUES
    (97, 1, l_par_refno, '01-APR-2015', 'SLFT-SITE-00003','Waste Site 1',10000,20000,100,
     'Y','N',l_par_refno, l_adr_refno);
     
  --- Insert the site address
  INSERT INTO addresses
     (adr_refno,adr_address_line_1,adr_address_line_2,adr_town,adr_postcode,adr_county,adr_country)
  VALUES
     (adr_seq.nextval,'The Huge Hole',NULL,'Northtown','NP7 8LB',NULL,'GB')
  RETURNING adr_refno INTO l_adr_refno;
  
  INSERT INTO landfill_sites
    (lasi_refno, lasi_version, lasi_par_refno, lasi_start_date, lasi_sepa_licence_number,lasi_site_name,lasi_lower_expected_tonnage,lasi_standard_expected_tonnage,lasi_exempt_expected_tonnage,
     lasi_weighbridge_ind,lasi_non_disposal_ind,lasi_controller_par_refno, lasi_adr_refno)
   VALUES
    (98, 1, l_par_refno, '01-APR-2018','SLFT-SITE-00004','Waste Site 2',15000,25000,150,
     'Y','N',l_par_refno, l_adr_refno);
     
     
  ---Creating data for SAT
  
  -- Create the Main account
  INSERT INTO parties
    (par_refno,par_type,par_com_company_name,par_org_name,par_marketing_ind,par_fact_type,par_fact_frd_domain,par_fact_srv_code,par_fact_wrk_refno,par_org_frv_oty_code)
  VALUES
    (par_refno_seq.nextval,'ORG','Test Portal Company SAT Users','Test Portal Company SAT Users','N','AGENT','PARTY_ACT_TYPES','SYS',1,'PARTNER')
  RETURNING par_refno INTO l_par_refno;
  
  create_or_maintain_cde(p_par_refno=>l_par_refno,p_cde_cme_code=>'EMAIL',p_value=>'noreply@necsws.com');
  create_or_maintain_cde(p_par_refno=>l_par_refno,p_cde_cme_code=>'PHONE',p_value=>'07700900321');
  create_or_maintain_address(p_refno=>l_par_refno,p_fao_code=>'PAR',p_adr_address_line_1=>'2 Park Lane',p_adr_address_line_2=>'Garden Village',p_adr_town=>'NORTHTOWN',p_adr_county=>'Northshire',p_adr_postcode=>'RG1 1PB');
        
  -- Note password is created by hashing the username and the password
  INSERT INTO users
     (usr_username,usr_password,usr_password_change_date,usr_force_pw_change,usr_current_ind,usr_name,usr_email_address,usr_wrk_refno,
      usr_int_user_ind,usr_par_refno,usr_per_forename,usr_per_surname,usr_pref_nld_code,usr_tac_signed_date)
  VALUES
     ('PORTAL.SAT.USERS',UPPER (dbms_obfuscation_toolkit.md5 (input => utl_i18n.string_to_raw('PORTAL.SAT.USERS'||'Password1!'))),TRUNC(SYSDATE),'N','Y','Portal SAT Users','noreply@necsws.com',3,
      'N',l_par_Refno,'Portal User','SAT Users','ENG',TRUNC(SYSDATE));
      
  INSERT INTO role_users
    (rus_rol_code,rus_usr_username)
  (SELECT rus_rol_code,'PORTAL.SAT.USERS'
    FROM role_users
   WHERE rus_usr_username = 'TEMPLATE_SELFSRV_USER');
   
   INSERT INTO user_services
    (use_username, use_service)
   VALUES
    ('PORTAL.SAT.USERS','SAT');
    
   --creating enrolment party 
   INSERT INTO parties
    (par_refno,par_type,par_org_name,par_org_frv_oty_code,par_fact_frd_domain,par_fact_srv_code,par_fact_wrk_refno)
  VALUES
    (par_refno_seq.nextval,'ORG','Marks & Spencer Group','PARTNER','PARTY_ACT_TYPES','SAT',1)
  RETURNING par_refno INTO l_enr_par_refno;
  
  dbms_output.put_line('l_enr_par_refno : ' || l_enr_par_refno );
  
  create_or_maintain_cde(p_par_refno=>l_enr_par_refno,p_cde_cme_code=>'EMAIL',p_value=>'noreply@necsws.com');
  create_or_maintain_cde(p_par_refno=>l_enr_par_refno,p_cde_cme_code=>'PHONE',p_value=>'07700900321');
  create_or_maintain_address(p_refno=>l_enr_par_refno,p_fao_code=>'PAR',p_adr_address_line_1=>'1 Acacia Avenue',p_adr_address_line_2=>'Garden Village',p_adr_town=>'NORTHTOWN',p_adr_county=>'Northshire',p_adr_postcode=>'RG1 1PB');
  
  history_tables_api.snapshot_party( p_par_refno       => l_enr_par_refno
                                       , p_snapshot_src_vn => NULL
                                       , p_parh_version    => l_h_version );
  
  --creating aggregate party
  INSERT INTO parties
    (par_refno,par_type,par_org_name,par_org_frv_oty_code,par_fact_frd_domain,par_fact_srv_code,par_fact_wrk_refno)
  VALUES
    (par_refno_seq.nextval,'ORG','Marks & Spencer Group','PARTNER','PARTY_ACT_TYPES','SAT',1)
  RETURNING par_refno INTO l_aggr_par_refno;
  
  dbms_output.put_line('l_aggr_par_refno : ' || l_aggr_par_refno );
  
  create_or_maintain_cde(p_par_refno=>l_aggr_par_refno,p_cde_cme_code=>'EMAIL',p_value=>'noreply@necsws.com');
  create_or_maintain_cde(p_par_refno=>l_aggr_par_refno,p_cde_cme_code=>'PHONE',p_value=>'07700900321');
  create_or_maintain_address(p_refno=>l_aggr_par_refno,p_fao_code=>'PAR',p_adr_address_line_1=>'1 Acacia Avenue',p_adr_address_line_2=>'Garden Village',p_adr_town=>'NORTHTOWN',p_adr_county=>'Northshire',p_adr_postcode=>'RG1 1PB');
    
  history_tables_api.snapshot_party( p_par_refno       => l_aggr_par_refno
                                       , p_snapshot_src_vn => NULL
                                       , p_parh_version    => l_h_version );
   
   --inerting into enrolment_master
   INSERT INTO enrolment_master (enrm_refno,enrm_registration_ref,enrm_par_refno,enrm_srv_code,enrm_effective_date,enrm_received_date,enrm_start_date,enrm_end_date,enrm_group_name) VALUES 
   (enrm_seq.NEXTVAL,'SAT1000000RPRP',l_enr_par_refno,'SAT',TRUNC(SYSDATE),TRUNC(SYSDATE),TRUNC(SYSDATE),null,NULL)
   returning enrm_refno INTO l_enrm_refno;
   
   dbms_output.put_line('l_enrm_refno : ' || l_enrm_refno );
   
   INSERT INTO tax_returns (tare_refno, tare_reference, tare_srv_code)
   VALUES(tare_seq.nextval,'RS1SAT1000000RPRP','SAT')
   RETURNING tare_refno INTO l_tare_refno;
   
   dbms_output.put_line('l_tare_refno : ' || l_tare_refno );   
  
   INSERT INTO portal_object_access(POA_PORTAL_PAR_REFNO, POA_OBJECT_TYPE, POA_OBJECT_REFERENCE)
   VALUES(l_par_Refno,'TARE_REFNO', l_tare_refno);
   
   INSERT INTO tax_return_versions (trv_tare_refno, trv_version, trv_latest_draft_ind, trv_source, trv_submitted_date, trv_start_date, trv_end_date, trv_enrm_refno, trv_declaration_date, trv_fpay_frd_domain, trv_fpay_wrk_refno, trv_fpay_srv_code)
   VALUES (l_tare_refno,1,'D','P','25-JUL-2024' ,'01-JUL-2024','31-JUL-2024',l_enrm_refno,SYSDATE,'PAYMENT TYPE',1,'SAT');
   
   INSERT INTO ENROLMENT_PERIODS (ep_refno,ep_enrm_refno,ep_start_date,ep_end_date,ep_effective_date,ep_status,ep_registration_type,ep_group_ind,ep_non_resident_ind,ep_using_agent_ind,ep_exploit_start,ep_est_quarry,ep_est_sand,ep_est_importation,ep_est_agg_levy,ep_est_exploited,ep_est_exempt,ep_est_export,ep_est_relief,ep_est_crusher,ep_est_other,ep_est_oth_description,ep_est_ere_ind,ep_est_cross_border,ep_take_over_ind,ep_transfer_date,ep_prv_reg_business_name,ep_prv_reg_org_type,ep_prv_reg_adr_refno,ep_prv_reg_retained,ep_prv_reg_no) 
   VALUES (ep_seq.NEXTVAL,l_enrm_refno,'01-AUG-2024',null,'01-AUG-2024','APPROVED','SINGLEREG','N','N','N',TRUNC(SYSDATE),100,200,300,400,500,600,700,800,900,1000,'created via Seed data','N',null,'N',null,null,null,null,null,null)
   RETURNING ep_refno INTO l_ep_refno;
   
   dbms_output.put_line('l_ep_refno : ' || l_ep_refno );
   
   INSERT INTO ENROLMENT_PERIOD_PARTIES (epp_ep_refno,epp_par_refno,epp_parh_version,epp_lead_ind,epp_group_controller_ind,epp_flink_type,epp_flink_frd_domain,epp_flink_wrk_refno,epp_flink_srv_code,epp_appoint_date,epp_reg_no,epp_same_corr_adr_ind)
   VALUES (l_ep_refno,l_enr_par_refno,1,null,null,'ENROLMENT','CASEPARTYLINKS',1,'SAT',TRUNC(SYSDATE),null,'Y');
   
   INSERT INTO ENROLMENT_PERIOD_PARTIES (epp_ep_refno,epp_par_refno,epp_parh_version,epp_lead_ind,epp_group_controller_ind,epp_flink_type,epp_flink_frd_domain,epp_flink_wrk_refno,epp_flink_srv_code,epp_appoint_date,epp_reg_no,epp_same_corr_adr_ind)   
   VALUES (l_ep_refno,l_aggr_par_refno,1,'N',null,'OPERATOR','CASEPARTYLINKS',1,'SAT',TRUNC(SYSDATE),'null','Y');
   
   INSERT INTO cases (
    case_refno,case_reference,
    case_caty_type,case_caty_srv_code,case_caty_wrk_refno,
    case_cast_status,case_casr_reason,
    case_automatic_ind,case_fcas_source,case_fcas_frd_domain,case_fcas_wrk_refno,case_fcas_srv_code,
    case_receipt_date,case_all_information_date,
    case_fobt_type,case_fobt_frd_domain,case_fobt_wrk_refno,case_fobt_srv_code,case_related_reference
  ) VALUES (
    case_seq.nextval,'PORTAL.SAT1000000RPRP',
    'ENROLMENT','SAT',1,
    'OPEN','ENROLMENT TO PROCESS',
    'Y','ONLINEFORM','CASESOURCES',1,'SAT',
    SYSDATE,NULL,
    'ENROLMENT','CASEOBJECTTYPES',1,'SAT','SAT1000000RPRP'
  ) 
  returning case_refno INTO l_case_refno;
  
  dbms_output.put_line('l_case_refno : ' || l_case_refno );
  
  INSERT INTO portal_object_access
  (POA_PORTAL_PAR_REFNO, POA_OBJECT_TYPE, POA_OBJECT_REFERENCE)
  VALUES
  (l_par_Refno,'ENRM_REFNO', l_enrm_refno);

   l_taxl_refno_seq := TAXL_SEQ.NEXTVAL;
   
   INSERT INTO taxable_locations( TAXL_REFNO, TAXL_EPP_PAR_REFNO, TAXL_ENRM_REFNO, TAXL_FTAXL_CODE, TAXL_FTAXL_FRD_DOMAIN, TAXL_FTAXL_WRK_REFNO, TAXL_FTAXL_SRV_CODE, TAXL_NAME, TAXL_START_DATE, TAXL_WEIGHBRIDGE_IND, TAXL_ADR_REFNO, TAXL_CONTACT_NAME, TAXL_EMAIL, TAXL_PHONE, TAXL_MOBILE, TAXL_COUNTRY_OPERATION, TAXL_CROSS_BORDER_IND, TAXL_FLAU_FRD_DOMAIN, TAXL_FLAU_WRK_REFNO, TAXL_FLAU_SRV_CODE)
   VALUES (l_taxl_refno_seq, L_AGGR_PAR_REFNO, l_enrm_refno, 'SITE','TAXL_LOCATION_TYPES',1,'SAT','Site1','01-JUL-2024','N', l_adr_refno, 'Site contact name','donotreply@necsws.com','07411222145','01542548965','SCOTLAND','N','UKLOCALAUTHS',1,'SAT')
   RETURNING TAXL_REFNO INTO l_taxl_refno1;

   l_taxl_refno_seq := TAXL_SEQ.NEXTVAL;
   
   INSERT INTO taxable_locations( TAXL_REFNO, TAXL_EPP_PAR_REFNO, TAXL_ENRM_REFNO, TAXL_FTAXL_CODE, TAXL_FTAXL_FRD_DOMAIN, TAXL_FTAXL_WRK_REFNO, TAXL_FTAXL_SRV_CODE, TAXL_NAME, TAXL_START_DATE, TAXL_WEIGHBRIDGE_IND, TAXL_ADR_REFNO, TAXL_CONTACT_NAME, TAXL_EMAIL, TAXL_PHONE, TAXL_MOBILE, TAXL_COUNTRY_OPERATION, TAXL_CROSS_BORDER_IND, TAXL_FLAU_FRD_DOMAIN, TAXL_FLAU_WRK_REFNO, TAXL_FLAU_SRV_CODE)
   VALUES (l_taxl_refno_seq, L_AGGR_PAR_REFNO, l_enrm_refno, 'SITE','TAXL_LOCATION_TYPES',1,'SAT','Site2','01-JUL-2024','N', l_adr_refno, 'Site contact name','donotreply@necsws.com','07411222145','01542548965','SCOTLAND','N','UKLOCALAUTHS',1,'SAT')
   RETURNING TAXL_REFNO INTO l_taxl_refno2;

   INSERT INTO tax_return_schedule_types(TRST_REFNO, TRST_ENRM_REFNO, TRST_START_DATE, TRST_END_DATE, TRST_FSCH_CODE, TRST_FSCH_FRD_DOMAIN, TRST_FSCH_WRK_REFNO, TRST_FSCH_SRV_CODE)
   VALUES (TRST_SEQ.NEXTVAL, l_enrm_refno, '01-APR-2024', NULL, 'ST4', 'SCHEDULETYPES', 1, 'SAT');
   
   INSERT INTO schd_type_return_periods(STRP_REFNO, STRP_FPROF_CODE, STRP_FPROF_DOMAIN, STRP_FPROF_SRV_CODE, STRP_FPROF_WRK_REFNO, STRP_START_DATE, STRP_END_DATE, STRP_DESCRIPTION)
   VALUES(STRP_SEQ.NEXTVAL, 'ST4','SCHEDULETYPES','SAT',1,TO_DATE('01-APR-2024', 'DD-MON-RRRR HH24:MI:SS'),'30-APR-2024','Period 2')
   RETURNING STRP_REFNO INTO l_strp_refno;

   dbms_output.put_line('l_strp_refno : ' || l_strp_refno );

   INSERT INTO schd_returns_period_breakdown(SRPB_REFNO, SRPB_STRP_REFNO, SRPB_START_DATE, SRPB_END_DATE)
   VALUES( srpb_seq.nextval, l_strp_refno, TO_DATE('01-APR-2024', 'DD-MON-RRRR HH24:MI:SS'), '30-APR-2024');
   
   INSERT INTO tax_returns (tare_refno, tare_reference, tare_srv_code)
   VALUES(tare_seq.nextval,'RS10000006AAFC','SAT')
   RETURNING tare_refno INTO l_tare_refno;

   dbms_output.put_line('l_tare_refno : ' || l_tare_refno );

   INSERT INTO tax_return_versions (trv_tare_refno, trv_version, trv_latest_draft_ind, trv_source, trv_submitted_date, trv_start_date, trv_end_date, trv_enrm_refno, trv_declaration_date, trv_fpay_method, trv_fpay_frd_domain, trv_fpay_wrk_refno, trv_fpay_srv_code)
   VALUES (l_tare_refno,1,'L','P',TO_DATE('21-APR-2024', 'DD-MON-RRRR HH24:MI:SS'),TO_DATE('01-APR-2024', 'DD-MON-RRRR HH24:MI:SS'),TO_DATE('30-APR-2024', 'DD-MON-RRRR HH24:MI:SS'), l_enrm_refno,TRUNC(SYSDATE),'BACS', 'PAYMENT TYPE',1,'SAT');

   INSERT INTO tax_return_schedules( TRS_REFNO, TRS_ENRM_REFNO, TRS_STRP_REFNO, TRS_PERIOD_START, TRS_PERIOD_END, TRS_TARE_REFNO, TRS_RETURN_STATUS)
   VALUES(TRS_SEQ.NEXTVAL,l_enrm_refno,l_strp_refno,TO_DATE('01-APR-2024', 'DD-MON-RRRR HH24:MI:SS'),TO_DATE('30-APR-2024', 'DD-MON-RRRR HH24:MI:SS'),l_tare_refno,'FILED')
   RETURNING TRS_REFNO INTO l_trs_refno;

   INSERT INTO tax_return_party_links(TRPL_TARE_REFNO, TRPL_TARE_VERSION, TRPL_PARH_PAR_REFNO, TRPL_PARH_VERSION, TRPL_LEAD_IND, TRPL_GROUP_CONTROLLER_IND, TRPL_FLINK_TYPE, TRPL_FLINK_FRD_DOMAIN, TRPL_FLINK_WRK_REFNO, TRPL_FLINK_SRV_CODE)
   VALUES (l_tare_refno, 1, l_aggr_par_refno, 1, 'N', NULL, 'OPERATOR', 'CASEPARTYLINKS', 1, 'SAT');

   INSERT INTO tax_return_party_links(TRPL_TARE_REFNO, TRPL_TARE_VERSION, TRPL_PARH_PAR_REFNO, TRPL_PARH_VERSION, TRPL_LEAD_IND, TRPL_GROUP_CONTROLLER_IND, TRPL_FLINK_TYPE, TRPL_FLINK_FRD_DOMAIN, TRPL_FLINK_WRK_REFNO, TRPL_FLINK_SRV_CODE)
   VALUES (l_tare_refno, 1, l_enr_par_refno, 1, NULL, NULL, 'ENROLMENT', 'CASEPARTYLINKS', 1, 'SAT');

   INSERT INTO trv_location_details(TLD_REFNO, TLD_TAXL_REFNO, TLD_TARE_REFNO, TLD_TARE_VERSION, TLD_START_DATE, TLD_END_DATE, TLD_TAXABLE_TONNAGE, TLD_EXEMPT_TONNAGE, TLD_TAX_DUE, TLD_TAX_CREDITS, TLD_TAX_PAYABLE)
   VALUES(TLD_SEQ.NEXTVAL, l_taxl_refno1, l_tare_refno, 1, '01-APR-2024', '30-APR-2024', 417.00, 20.00, 846.51, 325.00, 521.51) RETURNING TLD_REFNO INTO l_tld_refno;

   INSERT INTO trd_location_breakdown(TLB_TLD_REFNO,TLB_FLBD_CODE,TLB_FLBD_FRD_DOMAIN,TLB_FLBD_WRK_REFNO,TLB_FLBD_SRV_CODE,TLB_TONNAGE,TLB_RATE,TLB_WATER_TONNAGE,TLB_MIXED_IND,TLB_TAX_TOTAL,TLB_FATY_CODE,TLB_FATY_FRD_DOMAIN,TLB_FATY_WRK_REFNO,TLB_FATY_SRV_CODE,TLB_FAAT_CODE,TLB_FAAT_FRD_DOMAIN,TLB_FAAT_WRK_REFNO,TLB_FAAT_SRV_CODE,TLB_REL_TARE_REFNO,TLB_REL_PER_START,TLB_REL_PER_END,TLB_REFNO)
   values (l_tld_refno,'TAAG','RETURNATTRIBUTES',1,'SAT',517,2.03,100,'N',846.51,'SAND','AGGREGATE TYPE',1,'SAT','CONSTRUCT','COMMEXPLOITREASON',1,'SAT',null,null,null,TLB_SEQ.NEXTVAL);

   INSERT INTO trd_location_breakdown(TLB_TLD_REFNO,TLB_FLBD_CODE,TLB_FLBD_FRD_DOMAIN,TLB_FLBD_WRK_REFNO,TLB_FLBD_SRV_CODE,TLB_TONNAGE,TLB_RATE,TLB_WATER_TONNAGE,TLB_MIXED_IND,TLB_TAX_TOTAL,TLB_FATY_CODE,TLB_FATY_FRD_DOMAIN,TLB_FATY_WRK_REFNO,TLB_FATY_SRV_CODE,TLB_FAAT_CODE,TLB_FAAT_FRD_DOMAIN,TLB_FAAT_WRK_REFNO,TLB_FAAT_SRV_CODE,TLB_REL_TARE_REFNO,TLB_REL_PER_START,TLB_REL_PER_END,TLB_REFNO)
   values (l_tld_refno,'EXAG','RETURNATTRIBUTES',1,'SAT',20,null,null,'N',null,'ROCK','AGGREGATE TYPE',1,'SAT','CWOSOCLS','EXEMPTREASON',1,'SAT',null,null,null,TLB_SEQ.NEXTVAL);

   INSERT INTO trd_location_breakdown(TLB_TLD_REFNO,TLB_FLBD_CODE,TLB_FLBD_FRD_DOMAIN,TLB_FLBD_WRK_REFNO,TLB_FLBD_SRV_CODE,TLB_TONNAGE,TLB_RATE,TLB_WATER_TONNAGE,TLB_MIXED_IND,TLB_TAX_TOTAL,TLB_FATY_CODE,TLB_FATY_FRD_DOMAIN,TLB_FATY_WRK_REFNO,TLB_FATY_SRV_CODE,TLB_FAAT_CODE,TLB_FAAT_FRD_DOMAIN,TLB_FAAT_WRK_REFNO,TLB_FAAT_SRV_CODE,TLB_REL_TARE_REFNO,TLB_REL_PER_START,TLB_REL_PER_END,TLB_REFNO)
   values (l_tld_refno,'TACR','RETURNATTRIBUTES',1,'SAT',65,5,null,'N',325,'SAND','AGGREGATE TYPE',1,'SAT','EXCEPTED','TAXCREDITREASON',1,'SAT',null,null,null,TLB_SEQ.NEXTVAL);

   INSERT INTO trv_location_details(TLD_REFNO, TLD_TAXL_REFNO, TLD_TARE_REFNO, TLD_TARE_VERSION, TLD_START_DATE, TLD_END_DATE, TLD_TAXABLE_TONNAGE, TLD_EXEMPT_TONNAGE, TLD_TAX_DUE, TLD_TAX_CREDITS, TLD_TAX_PAYABLE)
   VALUES(TLD_SEQ.NEXTVAL, l_taxl_refno2, l_tare_refno, 1, '01-APR-2024', '30-APR-2024', 500.00, 100.00, 1015.00, 200, 815) RETURNING TLD_REFNO INTO l_tld_refno;

   INSERT INTO trd_location_breakdown(TLB_TLD_REFNO,TLB_FLBD_CODE,TLB_FLBD_FRD_DOMAIN,TLB_FLBD_WRK_REFNO,TLB_FLBD_SRV_CODE,TLB_TONNAGE,TLB_RATE,TLB_WATER_TONNAGE,TLB_MIXED_IND,TLB_TAX_TOTAL,TLB_FATY_CODE,TLB_FATY_FRD_DOMAIN,TLB_FATY_WRK_REFNO,TLB_FATY_SRV_CODE,TLB_FAAT_CODE,TLB_FAAT_FRD_DOMAIN,TLB_FAAT_WRK_REFNO,TLB_FAAT_SRV_CODE,TLB_REL_TARE_REFNO,TLB_REL_PER_START,TLB_REL_PER_END,TLB_REFNO)
   values (l_tld_refno,'TAAG','RETURNATTRIBUTES',1,'SAT',800,2.03,300,'N',1015.00,'SAND','AGGREGATE TYPE',1,'SAT','CONSTRUCT','COMMEXPLOITREASON',1,'SAT',null,null,null,TLB_SEQ.NEXTVAL);

   INSERT INTO trd_location_breakdown(TLB_TLD_REFNO,TLB_FLBD_CODE,TLB_FLBD_FRD_DOMAIN,TLB_FLBD_WRK_REFNO,TLB_FLBD_SRV_CODE,TLB_TONNAGE,TLB_RATE,TLB_WATER_TONNAGE,TLB_MIXED_IND,TLB_TAX_TOTAL,TLB_FATY_CODE,TLB_FATY_FRD_DOMAIN,TLB_FATY_WRK_REFNO,TLB_FATY_SRV_CODE,TLB_FAAT_CODE,TLB_FAAT_FRD_DOMAIN,TLB_FAAT_WRK_REFNO,TLB_FAAT_SRV_CODE,TLB_REL_TARE_REFNO,TLB_REL_PER_START,TLB_REL_PER_END,TLB_REFNO)
   values (l_tld_refno,'EXAG','RETURNATTRIBUTES',1,'SAT',100,null,null,'N',null,'ROCK','AGGREGATE TYPE',1,'SAT','CWOSOCLS','EXEMPTREASON',1,'SAT',null,null,null,TLB_SEQ.NEXTVAL);

   INSERT INTO trd_location_breakdown(TLB_TLD_REFNO,TLB_FLBD_CODE,TLB_FLBD_FRD_DOMAIN,TLB_FLBD_WRK_REFNO,TLB_FLBD_SRV_CODE,TLB_TONNAGE,TLB_RATE,TLB_WATER_TONNAGE,TLB_MIXED_IND,TLB_TAX_TOTAL,TLB_FATY_CODE,TLB_FATY_FRD_DOMAIN,TLB_FATY_WRK_REFNO,TLB_FATY_SRV_CODE,TLB_FAAT_CODE,TLB_FAAT_FRD_DOMAIN,TLB_FAAT_WRK_REFNO,TLB_FAAT_SRV_CODE,TLB_REL_TARE_REFNO,TLB_REL_PER_START,TLB_REL_PER_END,TLB_REFNO)
   values (l_tld_refno,'TACR','RETURNATTRIBUTES',1,'SAT',50,4,null,'N',200,'SAND','AGGREGATE TYPE',1,'SAT','EXCEPTED','TAXCREDITREASON',1,'SAT',null,null,null,TLB_SEQ.NEXTVAL);

   INSERT INTO portal_object_access(POA_PORTAL_PAR_REFNO,POA_OBJECT_TYPE,POA_OBJECT_REFERENCE, POA_CURRENT_IND)
   VALUES(l_par_Refno,'TARE_REFNO',l_tare_refno, 'Y');
   
    --*********************************
    -- Create the Financial accounts for the PORTAL.SAT.USERS account
    --*********************************
   INSERT INTO financial_accounts
     (fiac_refno,fiac_reference,fiac_wrk_refno,fiac_srv_code,fiac_suspense_ind)
   values
     (fiac_seq.nextval,'RS10000006AAFC',1,'SAT',NULL)
   RETURNING fiac_refno INTO l_fiac_refno;
    
   INSERT INTO fiac_party_links
     (fpli_par_refno,fpli_fiac_refno,
    fpli_ffpl_type,fpli_ffpl_frd_domain,fpli_ffpl_srv_code,fpli_ffpl_wrk_refno,fpli_authority_ind)
   VALUES (
    l_enr_par_refno,l_fiac_refno,'LIABLE','FIACPARTYLINKS','SAT',1,'N');
    
   INSERT INTO transactions
    (tra_refno,tra_actual_date,tra_effective_date,tra_fiac_refno,
    tra_tty_srv_code,tra_tty_code,tra_tty_wrk_refno,tra_amount,
    tra_related_reference,tra_related_subreference,tra_fobt_frd_domain, tra_fobt_srv_code, tra_fobt_type, tra_fobt_wrk_refno) 
   VALUES (
    tra_seq.nextval,'10-APR-2024','10-APR-2024',l_fiac_refno,
    'SAT','SAT',1,240,
    'RS10000006AAFC','1','OBJECT TYPES','SAT','RETURN',1)
   RETURNING tra_refno INTO l_ltra_refno;  
  
  -- creating new enrolment
  INSERT INTO parties
    (par_refno,par_type,par_org_name,par_org_frv_oty_code,par_fact_frd_domain,par_fact_srv_code,par_fact_wrk_refno)
  VALUES
    (par_refno_seq.nextval,'ORG','Black Sands Group','PARTNER','PARTY_ACT_TYPES','SAT',1)
  RETURNING par_refno INTO l_enr_par_refno;
  
  dbms_output.put_line('l_enr_par_refno : ' || l_enr_par_refno );
  
  create_or_maintain_cde(p_par_refno=>l_enr_par_refno,p_cde_cme_code=>'EMAIL',p_value=>'noreply@necsws.com');
  create_or_maintain_cde(p_par_refno=>l_enr_par_refno,p_cde_cme_code=>'PHONE',p_value=>'07700900321');
  create_or_maintain_address(p_refno=>l_enr_par_refno,p_fao_code=>'PAR',p_adr_address_line_1=>'1 Acacia Avenue',p_adr_address_line_2=>'Garden Village',p_adr_town=>'NORTHTOWN',p_adr_county=>'Northshire',p_adr_postcode=>'RG1 1PB');
  
  history_tables_api.snapshot_party( p_par_refno       => l_enr_par_refno
                                       , p_snapshot_src_vn => NULL
                                       , p_parh_version    => l_h_version );
  
  INSERT INTO parties
    (par_refno,par_type,par_org_name,par_org_frv_oty_code,par_fact_frd_domain,par_fact_srv_code,par_fact_wrk_refno)
  VALUES
    (par_refno_seq.nextval,'ORG','Black Sands Group','PARTNER','PARTY_ACT_TYPES','SAT',1)
  RETURNING par_refno INTO l_aggr_par_refno;
  
  dbms_output.put_line('l_aggr_par_refno : ' || l_aggr_par_refno );
  
  create_or_maintain_cde(p_par_refno=>l_aggr_par_refno,p_cde_cme_code=>'EMAIL',p_value=>'noreply@necsws.com');
  create_or_maintain_cde(p_par_refno=>l_aggr_par_refno,p_cde_cme_code=>'PHONE',p_value=>'07700900321');
  create_or_maintain_address(p_refno=>l_aggr_par_refno,p_fao_code=>'PAR',p_adr_address_line_1=>'1 Acacia Avenue',p_adr_address_line_2=>'Garden Village',p_adr_town=>'NORTHTOWN',p_adr_county=>'Northshire',p_adr_postcode=>'RG1 1PB');
    
  history_tables_api.snapshot_party( p_par_refno       => l_aggr_par_refno
                                       , p_snapshot_src_vn => NULL
                                       , p_parh_version    => l_h_version );
   
   INSERT INTO enrolment_master (enrm_refno,enrm_registration_ref,enrm_par_refno,enrm_srv_code,enrm_effective_date,enrm_received_date,enrm_start_date,enrm_end_date,enrm_group_name) VALUES 
   (enrm_seq.NEXTVAL,'SAT1000000VVVV',l_enr_par_refno,'SAT',TRUNC(SYSDATE),TRUNC(SYSDATE),TRUNC(SYSDATE),null,null)
   returning enrm_refno INTO l_enrm_refno;
   
   dbms_output.put_line('l_enrm_refno : ' || l_enrm_refno );
   
   INSERT INTO ENROLMENT_PERIODS (ep_refno,ep_enrm_refno,ep_start_date,ep_end_date,ep_effective_date,ep_status,ep_registration_type,ep_group_ind,ep_non_resident_ind,ep_using_agent_ind,ep_exploit_start,ep_est_quarry,ep_est_sand,ep_est_importation,ep_est_agg_levy,ep_est_exploited,ep_est_exempt,ep_est_export,ep_est_relief,ep_est_crusher,ep_est_other,ep_est_oth_description,ep_est_ere_ind,ep_est_cross_border,ep_take_over_ind,ep_transfer_date,ep_prv_reg_business_name,ep_prv_reg_org_type,ep_prv_reg_adr_refno,ep_prv_reg_retained,ep_prv_reg_no) 
   VALUES (ep_seq.NEXTVAL,l_enrm_refno,'01-AUG-2024',null,'01-AUG-2024','APPROVED','SINGLEREG','N','N','N',TRUNC(SYSDATE),100,200,300,400,500,600,700,800,900,1000,'created via Seed data','N',null,'N',null,null,null,null,null,null)
   returning ep_refno INTO l_ep_refno;
   
   dbms_output.put_line('l_ep_refno : ' || l_ep_refno );
   
   INSERT INTO ENROLMENT_PERIOD_PARTIES (epp_ep_refno,epp_par_refno,epp_parh_version,epp_lead_ind,epp_group_controller_ind,epp_flink_type,epp_flink_frd_domain,epp_flink_wrk_refno,epp_flink_srv_code,epp_appoint_date,epp_reg_no,epp_same_corr_adr_ind)
   VALUES (l_ep_refno,l_enr_par_refno,1,null,null,'ENROLMENT','CASEPARTYLINKS',1,'SAT',TRUNC(SYSDATE),null,'Y');
   
   INSERT INTO ENROLMENT_PERIOD_PARTIES (epp_ep_refno,epp_par_refno,epp_parh_version,epp_lead_ind,epp_group_controller_ind,epp_flink_type,epp_flink_frd_domain,epp_flink_wrk_refno,epp_flink_srv_code,epp_appoint_date,epp_reg_no,epp_same_corr_adr_ind)   
   VALUES (l_ep_refno,l_aggr_par_refno,1,'N',null,'OPERATOR','CASEPARTYLINKS',1,'SAT',TRUNC(SYSDATE),'null','Y');
   
   INSERT INTO cases (
    case_refno,case_reference,
    case_caty_type,case_caty_srv_code,case_caty_wrk_refno,
    case_cast_status,case_casr_reason,
    case_automatic_ind,case_fcas_source,case_fcas_frd_domain,case_fcas_wrk_refno,case_fcas_srv_code,
    case_receipt_date,case_all_information_date,
    case_fobt_type,case_fobt_frd_domain,case_fobt_wrk_refno,case_fobt_srv_code,case_related_reference
  ) VALUES (
    case_seq.nextval,'PORTAL.SAT1000000VVVV',
    'ENROLMENT','SAT',1,
    'OPEN','ENROLMENT TO PROCESS',
    'Y','ONLINEFORM','CASESOURCES',1,'SAT',
    SYSDATE,NULL,
    'ENROLMENT','CASEOBJECTTYPES',1,'SAT','SAT1000000VVVV'
  ) 
  returning case_refno INTO l_case_refno;
  
  dbms_output.put_line('l_case_refno : ' || l_case_refno );
  
  INSERT INTO portal_object_access
  (POA_PORTAL_PAR_REFNO, POA_OBJECT_TYPE, POA_OBJECT_REFERENCE)
  VALUES
  (l_par_Refno,'ENRM_REFNO', l_enrm_refno);
   
   INSERT INTO tax_returns (tare_refno, tare_reference, tare_srv_code)
   VALUES(tare_seq.nextval,'RS10000006BHDH','SAT')
   RETURNING tare_refno INTO l_tare_refno;

   dbms_output.put_line('l_tare_refno : ' || l_tare_refno );

   INSERT INTO tax_return_versions (trv_tare_refno, trv_version, trv_latest_draft_ind, trv_source, trv_submitted_date, trv_start_date, trv_end_date, trv_enrm_refno, trv_declaration_date, trv_fpay_method, trv_fpay_frd_domain, trv_fpay_wrk_refno, trv_fpay_srv_code)
   VALUES (l_tare_refno,1,'L','P','21-APR-2021','01-APR-2021',TO_DATE('30-APR-2021', 'DD-MON-RRRR HH24:MI:SS'), l_enrm_refno,TRUNC(SYSDATE),'BACS', 'PAYMENT TYPE',1,'SAT');

   INSERT INTO tax_return_schedules( TRS_REFNO, TRS_ENRM_REFNO, TRS_STRP_REFNO, TRS_PERIOD_START, TRS_PERIOD_END, TRS_TARE_REFNO, TRS_RETURN_STATUS)
   VALUES(TRS_SEQ.NEXTVAL,l_enrm_refno,l_strp_refno,'01-APR-2021',TO_DATE('30-APR-2021', 'DD-MON-RRRR HH24:MI:SS'),l_tare_refno,'FILED')
   RETURNING TRS_REFNO INTO l_trs_refno;

   INSERT INTO tax_return_party_links(TRPL_TARE_REFNO, TRPL_TARE_VERSION, TRPL_PARH_PAR_REFNO, TRPL_PARH_VERSION, TRPL_LEAD_IND, TRPL_GROUP_CONTROLLER_IND, TRPL_FLINK_TYPE, TRPL_FLINK_FRD_DOMAIN, TRPL_FLINK_WRK_REFNO, TRPL_FLINK_SRV_CODE)
   VALUES (l_tare_refno, 1, l_aggr_par_refno, 1, 'N', NULL, 'OPERATOR', 'CASEPARTYLINKS', 1, 'SAT');

   INSERT INTO tax_return_party_links(TRPL_TARE_REFNO, TRPL_TARE_VERSION, TRPL_PARH_PAR_REFNO, TRPL_PARH_VERSION, TRPL_LEAD_IND, TRPL_GROUP_CONTROLLER_IND, TRPL_FLINK_TYPE, TRPL_FLINK_FRD_DOMAIN, TRPL_FLINK_WRK_REFNO, TRPL_FLINK_SRV_CODE)
   VALUES (l_tare_refno, 1, l_enr_par_refno, 1, NULL, NULL, 'ENROLMENT', 'CASEPARTYLINKS', 1, 'SAT');

   INSERT INTO trv_location_details(TLD_REFNO, TLD_TAXL_REFNO, TLD_TARE_REFNO, TLD_TARE_VERSION, TLD_START_DATE, TLD_END_DATE, TLD_TAXABLE_TONNAGE, TLD_EXEMPT_TONNAGE, TLD_TAX_DUE, TLD_TAX_CREDITS, TLD_TAX_PAYABLE)
   VALUES(TLD_SEQ.NEXTVAL, l_taxl_refno1, l_tare_refno, 1, '01-APR-21', '30-APR-21', 417.00, 20.00, 846.51, 325.00, 521.51) RETURNING TLD_REFNO INTO l_tld_refno;

   INSERT INTO trd_location_breakdown(TLB_TLD_REFNO,TLB_FLBD_CODE,TLB_FLBD_FRD_DOMAIN,TLB_FLBD_WRK_REFNO,TLB_FLBD_SRV_CODE,TLB_TONNAGE,TLB_RATE,TLB_WATER_TONNAGE,TLB_MIXED_IND,TLB_TAX_TOTAL,TLB_FATY_CODE,TLB_FATY_FRD_DOMAIN,TLB_FATY_WRK_REFNO,TLB_FATY_SRV_CODE,TLB_FAAT_CODE,TLB_FAAT_FRD_DOMAIN,TLB_FAAT_WRK_REFNO,TLB_FAAT_SRV_CODE,TLB_REL_TARE_REFNO,TLB_REL_PER_START,TLB_REL_PER_END,TLB_REFNO)
   values (l_tld_refno,'TAAG','RETURNATTRIBUTES',1,'SAT',517,2.03,100,'N',846.51,'SAND','AGGREGATE TYPE',1,'SAT','CONSTRUCT','COMMEXPLOITREASON',1,'SAT',null,null,null,TLB_SEQ.NEXTVAL);

   INSERT INTO trd_location_breakdown(TLB_TLD_REFNO,TLB_FLBD_CODE,TLB_FLBD_FRD_DOMAIN,TLB_FLBD_WRK_REFNO,TLB_FLBD_SRV_CODE,TLB_TONNAGE,TLB_RATE,TLB_WATER_TONNAGE,TLB_MIXED_IND,TLB_TAX_TOTAL,TLB_FATY_CODE,TLB_FATY_FRD_DOMAIN,TLB_FATY_WRK_REFNO,TLB_FATY_SRV_CODE,TLB_FAAT_CODE,TLB_FAAT_FRD_DOMAIN,TLB_FAAT_WRK_REFNO,TLB_FAAT_SRV_CODE,TLB_REL_TARE_REFNO,TLB_REL_PER_START,TLB_REL_PER_END,TLB_REFNO)
   values (l_tld_refno,'EXAG','RETURNATTRIBUTES',1,'SAT',20,null,null,'N',null,'ROCK','AGGREGATE TYPE',1,'SAT','CWOSOCLS','EXEMPTREASON',1,'SAT',null,null,null,TLB_SEQ.NEXTVAL);

   INSERT INTO trd_location_breakdown(TLB_TLD_REFNO,TLB_FLBD_CODE,TLB_FLBD_FRD_DOMAIN,TLB_FLBD_WRK_REFNO,TLB_FLBD_SRV_CODE,TLB_TONNAGE,TLB_RATE,TLB_WATER_TONNAGE,TLB_MIXED_IND,TLB_TAX_TOTAL,TLB_FATY_CODE,TLB_FATY_FRD_DOMAIN,TLB_FATY_WRK_REFNO,TLB_FATY_SRV_CODE,TLB_FAAT_CODE,TLB_FAAT_FRD_DOMAIN,TLB_FAAT_WRK_REFNO,TLB_FAAT_SRV_CODE,TLB_REL_TARE_REFNO,TLB_REL_PER_START,TLB_REL_PER_END,TLB_REFNO)
   values (l_tld_refno,'TACR','RETURNATTRIBUTES',1,'SAT',65,5,null,'N',325,'SAND','AGGREGATE TYPE',1,'SAT','EXCEPTED','TAXCREDITREASON',1,'SAT',null,null,null,TLB_SEQ.NEXTVAL);

   INSERT INTO trv_location_details(TLD_REFNO, TLD_TAXL_REFNO, TLD_TARE_REFNO, TLD_TARE_VERSION, TLD_START_DATE, TLD_END_DATE, TLD_TAXABLE_TONNAGE, TLD_EXEMPT_TONNAGE, TLD_TAX_DUE, TLD_TAX_CREDITS, TLD_TAX_PAYABLE)
   VALUES(TLD_SEQ.NEXTVAL, l_taxl_refno2, l_tare_refno, 1, '01-APR-21', '30-APR-21', 500.00, 100.00, 1015.00, 200, 815) RETURNING TLD_REFNO INTO l_tld_refno;

   INSERT INTO trd_location_breakdown(TLB_TLD_REFNO,TLB_FLBD_CODE,TLB_FLBD_FRD_DOMAIN,TLB_FLBD_WRK_REFNO,TLB_FLBD_SRV_CODE,TLB_TONNAGE,TLB_RATE,TLB_WATER_TONNAGE,TLB_MIXED_IND,TLB_TAX_TOTAL,TLB_FATY_CODE,TLB_FATY_FRD_DOMAIN,TLB_FATY_WRK_REFNO,TLB_FATY_SRV_CODE,TLB_FAAT_CODE,TLB_FAAT_FRD_DOMAIN,TLB_FAAT_WRK_REFNO,TLB_FAAT_SRV_CODE,TLB_REL_TARE_REFNO,TLB_REL_PER_START,TLB_REL_PER_END,TLB_REFNO)
   values (l_tld_refno,'TAAG','RETURNATTRIBUTES',1,'SAT',800,2.03,300,'N',1015.00,'SAND','AGGREGATE TYPE',1,'SAT','CONSTRUCT','COMMEXPLOITREASON',1,'SAT',null,null,null,TLB_SEQ.NEXTVAL);

   INSERT INTO trd_location_breakdown(TLB_TLD_REFNO,TLB_FLBD_CODE,TLB_FLBD_FRD_DOMAIN,TLB_FLBD_WRK_REFNO,TLB_FLBD_SRV_CODE,TLB_TONNAGE,TLB_RATE,TLB_WATER_TONNAGE,TLB_MIXED_IND,TLB_TAX_TOTAL,TLB_FATY_CODE,TLB_FATY_FRD_DOMAIN,TLB_FATY_WRK_REFNO,TLB_FATY_SRV_CODE,TLB_FAAT_CODE,TLB_FAAT_FRD_DOMAIN,TLB_FAAT_WRK_REFNO,TLB_FAAT_SRV_CODE,TLB_REL_TARE_REFNO,TLB_REL_PER_START,TLB_REL_PER_END,TLB_REFNO)
   values (l_tld_refno,'EXAG','RETURNATTRIBUTES',1,'SAT',100,null,null,'N',null,'ROCK','AGGREGATE TYPE',1,'SAT','CWOSOCLS','EXEMPTREASON',1,'SAT',null,null,null,TLB_SEQ.NEXTVAL);

   INSERT INTO trd_location_breakdown(TLB_TLD_REFNO,TLB_FLBD_CODE,TLB_FLBD_FRD_DOMAIN,TLB_FLBD_WRK_REFNO,TLB_FLBD_SRV_CODE,TLB_TONNAGE,TLB_RATE,TLB_WATER_TONNAGE,TLB_MIXED_IND,TLB_TAX_TOTAL,TLB_FATY_CODE,TLB_FATY_FRD_DOMAIN,TLB_FATY_WRK_REFNO,TLB_FATY_SRV_CODE,TLB_FAAT_CODE,TLB_FAAT_FRD_DOMAIN,TLB_FAAT_WRK_REFNO,TLB_FAAT_SRV_CODE,TLB_REL_TARE_REFNO,TLB_REL_PER_START,TLB_REL_PER_END,TLB_REFNO)
   values (l_tld_refno,'TACR','RETURNATTRIBUTES',1,'SAT',50,4,null,'N',200,'SAND','AGGREGATE TYPE',1,'SAT','EXCEPTED','TAXCREDITREASON',1,'SAT',null,null,null,TLB_SEQ.NEXTVAL);

   INSERT INTO portal_object_access(POA_PORTAL_PAR_REFNO,POA_OBJECT_TYPE,POA_OBJECT_REFERENCE, POA_CURRENT_IND)
   VALUES(l_par_Refno,'TARE_REFNO',l_tare_refno, 'Y');

    INSERT INTO cases (
    case_refno,case_reference,
    case_caty_type,case_caty_srv_code,case_caty_wrk_refno,
    case_cast_status,case_casr_reason,case_description,
    case_automatic_ind,case_fcas_source,case_fcas_frd_domain,case_fcas_wrk_refno,case_fcas_srv_code,
    case_receipt_date,case_all_information_date,
    case_fobt_type,case_fobt_frd_domain,case_fobt_wrk_refno,case_fobt_srv_code,case_related_reference
  ) VALUES (
    case_seq.nextval,'PORTAL.RS10000006BHDH',
    'MESSAGE','SAT',1,
    'OPEN','SECURE MESSAGE RECEIVED','Test Data',
    'Y','DASHBOARD','CASESOURCES',1,'SAT',
    '01-JAN-2019','01-JAN-2019',
    'RETURN','OBJECT TYPES',1,'SAT','RS10000006BHDH'
  )
  returning case_refno INTO l_case_refno;
  
  INSERT INTO secure_messages (
    smsg_refno,smsg_original_refno,
    smsg_msgs_subject,smsg_msgs_frd_domain,smsg_msgs_wrk_refno,smsg_msgs_srv_code,
    smsg_title,smsg_body,smsg_case_refno,
    smsg_reference,
    smsg_read_ind,smsg_read_date,smsg_read_by, smsg_par_refno,smsg_direction,
    smsg_created_by,smsg_created_date,smsg_alt_reference,
    smsg_poa_object_type, smsg_poa_object_refno
  ) VALUES (
    smsg_seq.nextval,smsg_seq.currval,
    'SMSUBT007','MESSAGE_SUBJECT',1,'SYS',
    'Claim receipt confirmation','Body for Test Message 1',l_case_refno,
    'RS10000006BHDH',
    'N',NULL,NULL,l_par_refno,'O',
    'ADMIN@RSTU',TO_DATE('22-MAR-2019'),'ADMIN@RSTU',
    'ENRM_REFNO',l_enrm_refno
  )
  RETURNING smsg_refno INTO l_orig_smsg_refno;
  

  UPDATE secure_messages
  SET smsg_created_by = 'ADMIN@RSTU',smsg_created_date = TO_DATE('11-FEB-2025 08:48','DD-MON-YYYY HH24:MI')
  WHERE smsg_refno = l_orig_smsg_refno;

  INSERT INTO secure_messages (
    smsg_refno,smsg_original_refno,
    smsg_msgs_subject,smsg_msgs_frd_domain,smsg_msgs_wrk_refno,smsg_msgs_srv_code,
    smsg_title,smsg_body,smsg_case_refno,
    smsg_reference,
    smsg_read_ind,smsg_read_date,smsg_read_by, smsg_par_refno,smsg_direction,
    smsg_created_by,smsg_created_date,smsg_alt_reference,
    smsg_poa_object_type, smsg_poa_object_refno
  ) VALUES (
    smsg_seq.nextval,smsg_seq.currval,
    'SMSUBT007','MESSAGE_SUBJECT',1,'SYS',
    'Claim receipt confirmation','Body for Test Message 1',l_case_refno,
    'RS10000006BHDH',
    'N',NULL,NULL,l_par_refno,'O',
    'ADMIN@RSTU',TO_DATE('22-MAR-2019'),'ADMIN@RSTU',
    'ENRM_REFNO',l_enrm_refno
  )
  RETURNING smsg_refno INTO l_orig_smsg_refno;
  

  UPDATE secure_messages
  SET smsg_created_by = 'ADMIN@RSTU',smsg_created_date = TO_DATE('11-FEB-2025 06:18','DD-MON-YYYY HH24:MI')
  WHERE smsg_refno = l_orig_smsg_refno;
   
    --*********************************
    -- Create the Financial accounts for the PORTAL.SAT.USERS account
    --*********************************
   INSERT INTO financial_accounts
     (fiac_refno,fiac_reference,fiac_wrk_refno,fiac_srv_code,fiac_suspense_ind)
   values
     (fiac_seq.nextval,'RS10000006BHDH',1,'SAT',NULL)
   RETURNING fiac_refno INTO l_fiac_refno;
    
   INSERT INTO fiac_party_links
     (fpli_par_refno,fpli_fiac_refno,
    fpli_ffpl_type,fpli_ffpl_frd_domain,fpli_ffpl_srv_code,fpli_ffpl_wrk_refno,fpli_authority_ind)
   VALUES (
    l_enr_par_refno,l_fiac_refno,'LIABLE','FIACPARTYLINKS','SAT',1,'N');
    
   INSERT INTO transactions
    (tra_refno,tra_actual_date,tra_effective_date,tra_fiac_refno,
    tra_tty_srv_code,tra_tty_code,tra_tty_wrk_refno,tra_amount,
    tra_related_reference,tra_related_subreference,tra_fobt_frd_domain, tra_fobt_srv_code, tra_fobt_type, tra_fobt_wrk_refno) 
   VALUES (
    tra_seq.nextval,'10-APR-2021','10-APR-2021',l_fiac_refno,
    'SAT','SAT',1,240,
    'RS10000006BHDH','1','OBJECT TYPES','SAT','RETURN',1)
   RETURNING tra_refno INTO l_ltra_refno;
  
  INSERT INTO parties
    (par_refno,par_type,par_com_company_name,par_org_name,par_marketing_ind,par_fact_type,par_fact_frd_domain,par_fact_srv_code,par_fact_wrk_refno)
  VALUES
    (par_refno_seq.nextval,'ORG','Test Portal Company SAT Users2','Test Portal Company SAT Users2','N','AGENT','PARTY_ACT_TYPES','SYS',1)
  RETURNING par_refno INTO l_par_refno;


  -- Note password is created by hashing the username and the password
  INSERT INTO users
     (usr_username,usr_password,usr_password_change_date,usr_force_pw_change,usr_current_ind,usr_name,usr_email_address,usr_wrk_refno,
      usr_int_user_ind,usr_par_refno,usr_per_forename,usr_per_surname,usr_pref_nld_code,usr_tac_signed_date)
  VALUES
     ('PORTAL.SAT.TWO',UPPER (dbms_obfuscation_toolkit.md5 (input => utl_i18n.string_to_raw('PORTAL.SAT.TWO'||'Password1!'))),TRUNC(SYSDATE),'N','Y','Portal SAT TWO','noreply@necsws.com',3,
      'N',l_par_Refno,'Portal User','SAT TWO','ENG',TRUNC(SYSDATE));
      
  INSERT INTO role_users
    (rus_rol_code,rus_usr_username)
  (SELECT rus_rol_code,'PORTAL.SAT.TWO'
    FROM role_users
   WHERE rus_usr_username = 'TEMPLATE_SELFSRV_USER');
   
  INSERT INTO user_services
    (use_username, use_service)
   VALUES
    ('PORTAL.SAT.TWO','SAT');
  
  -- Create the Main account
  INSERT INTO parties
    (par_refno,par_type,par_com_company_name,par_org_name,par_marketing_ind,par_fact_type,par_fact_frd_domain,par_fact_srv_code,par_fact_wrk_refno)
  VALUES
    (par_refno_seq.nextval,'ORG','Test Portal Company SAT Users1','Test Portal Company SAT Users1','N','AGENT','PARTY_ACT_TYPES','SYS',1)
  RETURNING par_refno INTO l_par_refno;
  
  create_or_maintain_cde(p_par_refno=>l_par_refno,p_cde_cme_code=>'EMAIL',p_value=>'noreply@necsws.com');
  create_or_maintain_cde(p_par_refno=>l_par_refno,p_cde_cme_code=>'PHONE',p_value=>'07700900321');
  create_or_maintain_address(p_refno=>l_par_refno,p_fao_code=>'PAR',p_adr_address_line_1=>'2 Park Lane',p_adr_address_line_2=>'Garden Village',p_adr_town=>'NORTHTOWN',p_adr_county=>'Northshire',p_adr_postcode=>'RG1 1PB');
  
  -- Note password is created by hashing the username and the password
  INSERT INTO users
     (usr_username,usr_password,usr_password_change_date,usr_force_pw_change,usr_current_ind,usr_name,usr_email_address,usr_wrk_refno,
      usr_int_user_ind,usr_par_refno,usr_per_forename,usr_per_surname,usr_pref_nld_code,usr_tac_signed_date)
  VALUES
     ('PORTAL.SAT.ONE',UPPER (dbms_obfuscation_toolkit.md5 (input => utl_i18n.string_to_raw('PORTAL.SAT.ONE'||'Password1!'))),TRUNC(SYSDATE),'N','Y','Portal SAT One','noreply@necsws.com',3,
      'N',l_par_Refno,'Portal User','SAT one','ENG',TRUNC(SYSDATE));
      
  INSERT INTO role_users
    (rus_rol_code,rus_usr_username)
  (SELECT rus_rol_code,'PORTAL.SAT.ONE'
    FROM role_users
   WHERE rus_usr_username = 'TEMPLATE_SELFSRV_USER');
   
  INSERT INTO user_services
    (use_username, use_service)
   VALUES
    ('PORTAL.SAT.ONE','SAT'); 
       
  INSERT INTO parties
    (par_refno,par_type,par_org_name,par_org_frv_oty_code,par_fact_frd_domain,par_fact_srv_code,par_fact_wrk_refno)
  VALUES
    (par_refno_seq.nextval,'ORG','Kevin Peterson Partnership','PARTNER','PARTY_ACT_TYPES','SAT',1)
  RETURNING par_refno INTO l_enr_par_refno;
  
  dbms_output.put_line('l_enr_par_refno : ' || l_enr_par_refno );
  
  INSERT INTO dd_instructions (
    din_refno,din_par_refno,din_start_date,
    din_bank_sort_code,din_bank_account_number,din_bank_bsoc_roll_number,
    din_first_dd_taken_ind,din_auddis_code,din_auddis_trans_date,din_bank_account_name,
    din_mandate_reference
    ) VALUES (
    din_seq.nextval,l_enr_par_refno,TO_DATE('01-JAN-2019','DD-MON-YYYY'),
    '00-00-00','12345678','0',
    'N','NP',TO_DATE('01-JAN-2019','DD-MON-YYYY'),'Portal Test','RS1235');
  
  create_or_maintain_cde(p_par_refno=>l_enr_par_refno,p_cde_cme_code=>'EMAIL',p_value=>'noreply@necsws.com');
  create_or_maintain_cde(p_par_refno=>l_enr_par_refno,p_cde_cme_code=>'PHONE',p_value=>'07700900321');
  create_or_maintain_address(p_refno=>l_enr_par_refno,p_fao_code=>'PAR',p_adr_address_line_1=>'1 Acacia Avenue',p_adr_address_line_2=>'Garden Village',p_adr_town=>'NORTHTOWN',p_adr_county=>'Northshire',p_adr_postcode=>'RG1 1PB');
  
  history_tables_api.snapshot_party( p_par_refno       => l_enr_par_refno
                                       , p_snapshot_src_vn => NULL
                                       , p_parh_version    => l_h_version );
  
  INSERT INTO parties
    (par_refno,par_type,par_org_name,par_org_frv_oty_code,par_fact_frd_domain,par_fact_srv_code,par_fact_wrk_refno)
  VALUES
    (par_refno_seq.nextval,'ORG','Kevin Peterson Partnership','PARTNER','PARTY_ACT_TYPES','SAT',1)
  RETURNING par_refno INTO l_aggr_par_refno;
  
  dbms_output.put_line('l_aggr_par_refno : ' || l_aggr_par_refno );
  
  create_or_maintain_cde(p_par_refno=>l_aggr_par_refno,p_cde_cme_code=>'EMAIL',p_value=>'noreply@necsws.com');
  create_or_maintain_cde(p_par_refno=>l_aggr_par_refno,p_cde_cme_code=>'PHONE',p_value=>'07700900321');
  create_or_maintain_address(p_refno=>l_aggr_par_refno,p_fao_code=>'PAR',p_adr_address_line_1=>'1 Acacia Avenue',p_adr_address_line_2=>'Garden Village',p_adr_town=>'NORTHTOWN',p_adr_county=>'Northshire',p_adr_postcode=>'RG1 1PB');
    
  history_tables_api.snapshot_party( p_par_refno       => l_aggr_par_refno
                                       , p_snapshot_src_vn => NULL
                                       , p_parh_version    => l_h_version );
   
   INSERT INTO enrolment_master (enrm_refno,enrm_registration_ref,enrm_par_refno,enrm_srv_code,enrm_effective_date,enrm_received_date,enrm_start_date,enrm_end_date,enrm_group_name) values 
   (enrm_seq.NEXTVAL,'SAT1000000TVTV',l_enr_par_refno,'SAT','01-AUG-2024','01-AUG-2024','01-AUG-2024',null,'Group 54')
   RETURNING enrm_refno INTO l_enrm_refno;
   
   dbms_output.put_line('l_enrm_refno : ' || l_enrm_refno );
   
   INSERT INTO tax_returns (tare_refno, tare_reference, tare_srv_code)
   VALUES(tare_seq.nextval,'RS11000000TVTV','SAT')
   RETURNING tare_refno INTO l_tare_refno;
   
   dbms_output.put_line('l_tare_refno : ' || l_tare_refno );  
   
   INSERT INTO portal_object_access(POA_PORTAL_PAR_REFNO, POA_OBJECT_TYPE, POA_OBJECT_REFERENCE)
   VALUES(l_par_Refno,'TARE_REFNO', l_tare_refno);
   
   INSERT INTO tax_return_versions (trv_tare_refno, trv_version, trv_latest_draft_ind, trv_source, trv_submitted_date, trv_start_date, trv_end_date, trv_enrm_refno, trv_declaration_date, trv_fpay_frd_domain, trv_fpay_wrk_refno, trv_fpay_srv_code)
   VALUES (l_tare_refno,1,'D','P','25-JUL-2024' ,'01-JUL-2024','31-JUL-2024',l_enrm_refno,TRUNC(SYSDATE),'PAYMENT TYPE',1,'SAT');
   
   
   INSERT INTO ENROLMENT_PERIODS (ep_refno,ep_enrm_refno,ep_start_date,ep_end_date,ep_effective_date,ep_status,ep_registration_type,ep_group_ind,ep_non_resident_ind,ep_using_agent_ind,ep_exploit_start,ep_est_quarry,ep_est_sand,ep_est_importation,ep_est_agg_levy,ep_est_exploited,ep_est_exempt,ep_est_export,ep_est_relief,ep_est_crusher,ep_est_other,ep_est_oth_description,ep_est_ere_ind,ep_est_cross_border,ep_take_over_ind,ep_transfer_date,ep_prv_reg_business_name,ep_prv_reg_org_type,ep_prv_reg_adr_refno,ep_prv_reg_retained,ep_prv_reg_no) 
   VALUES (ep_seq.NEXTVAL,l_enrm_refno,'01-AUG-2024',null,'01-AUG-2024','APPROVED','SINGLEREG','N','N','N',TRUNC(SYSDATE),100,200,300,400,500,600,700,800,900,1000,'created via Seed data','N',null,'N',null,null,null,null,null,null)
   RETURNING ep_refno INTO l_ep_refno;
   
   dbms_output.put_line('l_ep_refno : ' || l_ep_refno );
   
   INSERT INTO ENROLMENT_PERIOD_PARTIES (epp_ep_refno,epp_par_refno,epp_parh_version,epp_lead_ind,epp_group_controller_ind,epp_flink_type,epp_flink_frd_domain,epp_flink_wrk_refno,epp_flink_srv_code,epp_appoint_date,epp_reg_no,epp_same_corr_adr_ind)
   VALUES (l_ep_refno,l_enr_par_refno,1,null,null,'ENROLMENT','CASEPARTYLINKS',1,'SAT',TRUNC(SYSDATE),null,'Y');
   
   INSERT INTO ENROLMENT_PERIOD_PARTIES (epp_ep_refno,epp_par_refno,epp_parh_version,epp_lead_ind,epp_group_controller_ind,epp_flink_type,epp_flink_frd_domain,epp_flink_wrk_refno,epp_flink_srv_code,epp_appoint_date,epp_reg_no,epp_same_corr_adr_ind)   
   VALUES (l_ep_refno,l_aggr_par_refno,1,'N',null,'OPERATOR','CASEPARTYLINKS',1,'SAT',TRUNC(SYSDATE),'null','Y');
   
   l_strp_seq := STRP_SEQ.NEXTVAL;
   l_taxl_refno_seq := TAXL_SEQ.NEXTVAL;
   
   INSERT INTO schd_type_return_periods(STRP_REFNO, STRP_FPROF_CODE, STRP_FPROF_DOMAIN, STRP_FPROF_SRV_CODE, STRP_FPROF_WRK_REFNO, STRP_START_DATE, STRP_END_DATE, STRP_DESCRIPTION)
   VALUES(l_strp_seq, 'ST1','SCHEDULETYPES','SAT',1,TO_DATE('01-APR-2024', 'DD-MON-RRRR HH24:MI:SS'),'30-JUN-2024','Period 1');

   INSERT INTO tax_return_schedules( TRS_REFNO, TRS_ENRM_REFNO, TRS_STRP_REFNO, TRS_PERIOD_START, TRS_PERIOD_END)
   VALUES(TRS_SEQ.NEXTVAL,l_enrm_refno,l_strp_seq,'01-JUL-2024','31-JUL-2024');


   INSERT INTO schd_returns_period_breakdown( SRPB_REFNO, SRPB_STRP_REFNO, SRPB_START_DATE, SRPB_END_DATE)
   VALUES(SRPB_SEQ.NEXTVAL,l_strp_seq,'01-JUL-2024', '31-JUL-2024');
   
   INSERT INTO taxable_locations( TAXL_REFNO, TAXL_EPP_PAR_REFNO, TAXL_ENRM_REFNO, TAXL_FTAXL_CODE, TAXL_FTAXL_FRD_DOMAIN, TAXL_FTAXL_WRK_REFNO, TAXL_FTAXL_SRV_CODE, TAXL_NAME, TAXL_START_DATE, TAXL_WEIGHBRIDGE_IND, TAXL_ADR_REFNO, TAXL_CONTACT_NAME, TAXL_EMAIL, TAXL_PHONE, TAXL_MOBILE, TAXL_COUNTRY_OPERATION, TAXL_CROSS_BORDER_IND, TAXL_FLAU_FRD_DOMAIN, TAXL_FLAU_WRK_REFNO, TAXL_FLAU_SRV_CODE)
   VALUES (l_taxl_refno_seq, L_AGGR_PAR_REFNO, l_enrm_refno, 'SITE','TAXL_LOCATION_TYPES',1,'SAT','Site1','01-JUL-2024','N', l_adr_refno, 'Site contact name','donotreply@necsws.com','07411222145','01542548965','SCOTLAND','N','UKLOCALAUTHS',1,'SAT')
   RETURNING TAXL_REFNO INTO l_taxl_refno1;

   l_taxl_refno_seq := TAXL_SEQ.NEXTVAL;
   
   INSERT INTO taxable_locations( TAXL_REFNO, TAXL_EPP_PAR_REFNO, TAXL_ENRM_REFNO, TAXL_FTAXL_CODE, TAXL_FTAXL_FRD_DOMAIN, TAXL_FTAXL_WRK_REFNO, TAXL_FTAXL_SRV_CODE, TAXL_NAME, TAXL_START_DATE, TAXL_WEIGHBRIDGE_IND, TAXL_ADR_REFNO, TAXL_CONTACT_NAME, TAXL_EMAIL, TAXL_PHONE, TAXL_MOBILE, TAXL_COUNTRY_OPERATION, TAXL_CROSS_BORDER_IND, TAXL_FLAU_FRD_DOMAIN, TAXL_FLAU_WRK_REFNO, TAXL_FLAU_SRV_CODE)
   VALUES (l_taxl_refno_seq, L_AGGR_PAR_REFNO, l_enrm_refno, 'SITE','TAXL_LOCATION_TYPES',1,'SAT','Site2','01-JUL-2024','N', l_adr_refno, 'Site contact name','donotreply@necsws.com','07411222145','01542548965','SCOTLAND','N','UKLOCALAUTHS',1,'SAT')
   RETURNING TAXL_REFNO INTO l_taxl_refno2;

   l_strp_seq := STRP_SEQ.NEXTVAL;
   
   INSERT INTO schd_type_return_periods(STRP_REFNO, STRP_FPROF_CODE, STRP_FPROF_DOMAIN, STRP_FPROF_SRV_CODE, STRP_FPROF_WRK_REFNO, STRP_START_DATE, STRP_END_DATE, STRP_DESCRIPTION)
   VALUES(l_strp_seq, 'ST1','SCHEDULETYPES','SAT',1,'01-JUL-2024','30-SEP-2024','Period 2');
   
   INSERT INTO schd_returns_period_breakdown( SRPB_REFNO, SRPB_STRP_REFNO, SRPB_START_DATE, SRPB_END_DATE)
   VALUES(SRPB_SEQ.NEXTVAL,l_strp_seq,'01-AUG-2024','31-AUG-2024');
   
   INSERT INTO tax_return_schedules( TRS_REFNO, TRS_ENRM_REFNO, TRS_STRP_REFNO, TRS_PERIOD_START, TRS_PERIOD_END)
   VALUES(TRS_SEQ.NEXTVAL,l_enrm_refno,l_strp_seq,'01-AUG-2024','31-AUG-2024');


   INSERT INTO tax_returns (tare_refno, tare_reference, tare_srv_code)
   VALUES(tare_seq.nextval,'RS11000000BSJA','SAT')
   RETURNING tare_refno INTO l_tare_refno;
   
   dbms_output.put_line('l_tare_refno : ' || l_tare_refno );  
   
   INSERT INTO tax_return_versions (trv_tare_refno, trv_version, trv_latest_draft_ind, trv_source, trv_submitted_date, trv_start_date, trv_end_date, trv_enrm_refno, trv_declaration_date, trv_fpay_frd_domain, trv_fpay_wrk_refno, trv_fpay_srv_code)
   VALUES (l_tare_refno,1,'D','P','25-JUL-2024' ,'01-JUL-2024','31-JUL-2024',l_enrm_refno,TRUNC(SYSDATE),'PAYMENT TYPE',1,'SAT');
      
   INSERT INTO cases (
    case_refno,case_reference,
    case_caty_type,case_caty_srv_code,case_caty_wrk_refno,
    case_cast_status,case_casr_reason,
    case_automatic_ind,case_fcas_source,case_fcas_frd_domain,case_fcas_wrk_refno,case_fcas_srv_code,
    case_receipt_date,case_all_information_date,
    case_fobt_type,case_fobt_frd_domain,case_fobt_wrk_refno,case_fobt_srv_code,case_related_reference
  ) VALUES (
    case_seq.nextval,'PORTAL.SAT1000000TVTV',
    'ENROLMENT','SAT',1,
    'OPEN','ENROLMENT TO PROCESS',
    'Y','ONLINEFORM','CASESOURCES',1,'SAT',
    SYSDATE,NULL,
    'ENROLMENT','CASEOBJECTTYPES',1,'SAT','SAT1000000TVTV'
  ) 
  RETURNING case_refno INTO l_case_refno;
  
  dbms_output.put_line('l_case_refno : ' || l_case_refno );
  
  INSERT INTO portal_object_access
  (POA_PORTAL_PAR_REFNO, POA_OBJECT_TYPE, POA_OBJECT_REFERENCE)
  VALUES
  (l_par_Refno,'ENRM_REFNO', l_enrm_refno);

   INSERT INTO tax_return_schedule_types(TRST_REFNO, TRST_ENRM_REFNO, TRST_START_DATE, TRST_END_DATE, TRST_FSCH_CODE, TRST_FSCH_FRD_DOMAIN, TRST_FSCH_WRK_REFNO, TRST_FSCH_SRV_CODE)
   VALUES (TRST_SEQ.NEXTVAL, l_enrm_refno, '01-JUN-24', NULL, 'ST4', 'SCHEDULETYPES', 1, 'SAT');
   
   INSERT INTO schd_type_return_periods(STRP_REFNO, STRP_FPROF_CODE, STRP_FPROF_DOMAIN, STRP_FPROF_SRV_CODE, STRP_FPROF_WRK_REFNO, STRP_START_DATE, STRP_END_DATE, STRP_DESCRIPTION)
   VALUES(STRP_SEQ.NEXTVAL, 'ST4','SCHEDULETYPES','SAT',1,'01-JUN-2024','30-JUN-2024','Period 1')
   RETURNING STRP_REFNO INTO l_strp_refno;

   dbms_output.put_line('l_strp_refno : ' || l_strp_refno );

   INSERT INTO schd_returns_period_breakdown(SRPB_REFNO, SRPB_STRP_REFNO, SRPB_START_DATE, SRPB_END_DATE)
   VALUES( srpb_seq.nextval, l_strp_refno, '01-JUN-2024', '30-JUN-2024');
   
   INSERT INTO tax_returns (tare_refno, tare_reference, tare_srv_code)
   VALUES(tare_seq.nextval,'RS10000001RPTS','SAT')
   RETURNING tare_refno INTO l_tare_refno;

   dbms_output.put_line('l_tare_refno : ' || l_tare_refno );

   INSERT INTO tax_return_versions (trv_tare_refno, trv_version, trv_latest_draft_ind, trv_source, trv_submitted_date, trv_start_date, trv_end_date, trv_enrm_refno, trv_declaration_date, trv_fpay_method, trv_fpay_frd_domain, trv_fpay_wrk_refno, trv_fpay_srv_code)
   VALUES (l_tare_refno,1,'L','P','25-JUN-2024','01-JUN-2024','30-JUN-2024', l_enrm_refno,TRUNC(SYSDATE),'BACS','PAYMENT TYPE',1,'SAT');

   INSERT INTO tax_return_schedules( TRS_REFNO, TRS_ENRM_REFNO, TRS_STRP_REFNO, TRS_PERIOD_START, TRS_PERIOD_END, TRS_TARE_REFNO, TRS_RETURN_STATUS)
   VALUES(TRS_SEQ.NEXTVAL,l_enrm_refno,l_strp_refno,'01-JUN-2024','30-JUN-2024',l_tare_refno,'FILED')
   RETURNING TRS_REFNO INTO l_trs_refno;

   INSERT INTO tax_return_party_links(TRPL_TARE_REFNO, TRPL_TARE_VERSION, TRPL_PARH_PAR_REFNO, TRPL_PARH_VERSION, TRPL_LEAD_IND, TRPL_GROUP_CONTROLLER_IND, TRPL_FLINK_TYPE, TRPL_FLINK_FRD_DOMAIN, TRPL_FLINK_WRK_REFNO, TRPL_FLINK_SRV_CODE)
   VALUES (l_tare_refno, 1, l_aggr_par_refno, 1, 'N', NULL, 'OPERATOR', 'CASEPARTYLINKS', 1, 'SAT');

   INSERT INTO tax_return_party_links(TRPL_TARE_REFNO, TRPL_TARE_VERSION, TRPL_PARH_PAR_REFNO, TRPL_PARH_VERSION, TRPL_LEAD_IND, TRPL_GROUP_CONTROLLER_IND, TRPL_FLINK_TYPE, TRPL_FLINK_FRD_DOMAIN, TRPL_FLINK_WRK_REFNO, TRPL_FLINK_SRV_CODE)
   VALUES (l_tare_refno, 1, l_enr_par_refno, 1, NULL, NULL, 'ENROLMENT', 'CASEPARTYLINKS', 1, 'SAT');

   INSERT INTO trv_location_details(TLD_REFNO, TLD_TAXL_REFNO, TLD_TARE_REFNO, TLD_TARE_VERSION, TLD_START_DATE, TLD_END_DATE, TLD_TAXABLE_TONNAGE, TLD_EXEMPT_TONNAGE, TLD_TAX_DUE, TLD_TAX_CREDITS, TLD_TAX_PAYABLE)
   VALUES(TLD_SEQ.NEXTVAL, l_taxl_refno1, l_tare_refno, 1, '01-JUN-24', '30-JUN-24', 431.00, 344.00, 874.93, 759.00, 115.93);

   INSERT INTO trv_location_details(TLD_REFNO, TLD_TAXL_REFNO, TLD_TARE_REFNO, TLD_TARE_VERSION, TLD_START_DATE, TLD_END_DATE, TLD_TAXABLE_TONNAGE, TLD_EXEMPT_TONNAGE, TLD_TAX_DUE, TLD_TAX_CREDITS, TLD_TAX_PAYABLE)
   VALUES(TLD_SEQ.NEXTVAL, l_taxl_refno2, l_tare_refno, 1, '01-JUN-24', '30-JUN-24', 786.00, 1118.00, 1595.58, 1191, 404.58);

   INSERT INTO portal_object_access(POA_PORTAL_PAR_REFNO,POA_OBJECT_TYPE,POA_OBJECT_REFERENCE, POA_CURRENT_IND)
   VALUES(l_par_Refno,'TARE_REFNO',l_tare_refno, 'Y');
   
   INSERT INTO schd_type_return_periods(STRP_REFNO, STRP_FPROF_CODE, STRP_FPROF_DOMAIN, STRP_FPROF_SRV_CODE, STRP_FPROF_WRK_REFNO, STRP_START_DATE, STRP_END_DATE, STRP_DESCRIPTION)
   VALUES(STRP_SEQ.NEXTVAL, 'ST4','SCHEDULETYPES','SAT',1,'01-JUL-2024','31-JUL-2024','Period 2')
   RETURNING STRP_REFNO INTO l_strp_refno;

   dbms_output.put_line('l_strp_refno : ' || l_strp_refno );

   INSERT INTO schd_returns_period_breakdown(SRPB_REFNO, SRPB_STRP_REFNO, SRPB_START_DATE, SRPB_END_DATE)
   VALUES( srpb_seq.nextval, l_strp_refno, '01-JUL-2024', '31-JUL-2024');

    --*********************************
    -- Create the Financial accounts for the PORTAL.SAT.USERS account
    --*********************************
   INSERT INTO financial_accounts
     (fiac_refno,fiac_reference,fiac_wrk_refno,fiac_srv_code,fiac_suspense_ind)
   values
     (fiac_seq.nextval,'RS10000001RPTS',1,'SAT',NULL)
   RETURNING fiac_refno INTO l_fiac_refno;
    
   INSERT INTO fiac_party_links
     (fpli_par_refno,fpli_fiac_refno,
    fpli_ffpl_type,fpli_ffpl_frd_domain,fpli_ffpl_srv_code,fpli_ffpl_wrk_refno,fpli_authority_ind)
   VALUES (
    l_enr_par_refno,l_fiac_refno,'LIABLE','FIACPARTYLINKS','SAT',1,'N');
    
   INSERT INTO transactions
    (tra_refno,tra_actual_date,tra_effective_date,tra_fiac_refno,
    tra_tty_srv_code,tra_tty_code,tra_tty_wrk_refno,tra_amount,
    tra_related_reference,tra_related_subreference,tra_fobt_frd_domain, tra_fobt_srv_code, tra_fobt_type, tra_fobt_wrk_refno) 
   VALUES (
    tra_seq.nextval,'10-JAN-2024','10-JAN-2024',l_fiac_refno,
    'SAT','SAT',1,150,
    'RS10000001RPTS','1','OBJECT TYPES','SAT','RETURN',1)
   RETURNING tra_refno INTO l_ltra_refno;
   
   INSERT INTO tax_returns (tare_refno, tare_reference, tare_srv_code)
   VALUES(tare_seq.nextval,'RS10000002ZPTS','SAT')
   RETURNING tare_refno INTO l_tare_refno;

   dbms_output.put_line('l_tare_refno : ' || l_tare_refno );

   INSERT INTO tax_return_versions (trv_tare_refno, trv_version, trv_latest_draft_ind, trv_source, trv_submitted_date, trv_start_date, trv_end_date, trv_enrm_refno, trv_declaration_date, trv_fpay_frd_domain, trv_fpay_wrk_refno, trv_fpay_srv_code)
   VALUES (l_tare_refno,1,'D','P','25-JUN-2024','01-JUN-2024','30-JUN-2024', l_enrm_refno,TRUNC(SYSDATE),'PAYMENT TYPE',1,'SAT');

   INSERT INTO tax_return_schedules( TRS_REFNO, TRS_ENRM_REFNO, TRS_STRP_REFNO, TRS_PERIOD_START, TRS_PERIOD_END, TRS_TARE_REFNO, TRS_RETURN_STATUS)
   VALUES(TRS_SEQ.NEXTVAL,l_enrm_refno,l_strp_refno,'02-JUN-2024','30-JUN-2024',l_tare_refno,'FILED')
   RETURNING TRS_REFNO INTO l_trs_refno;
   
   INSERT INTO financial_accounts
     (fiac_refno,fiac_reference,fiac_wrk_refno,fiac_srv_code,fiac_suspense_ind)
   values
     (fiac_seq.nextval,'RS10000002ZPTS',1,'SAT',NULL)
   RETURNING fiac_refno INTO l_fiac_refno;
    
   INSERT INTO fiac_party_links
     (fpli_par_refno,fpli_fiac_refno,
    fpli_ffpl_type,fpli_ffpl_frd_domain,fpli_ffpl_srv_code,fpli_ffpl_wrk_refno,fpli_authority_ind)
   VALUES (
    l_enr_par_refno,l_fiac_refno,'LIABLE','FIACPARTYLINKS','SAT',1,'N');
    
   INSERT INTO transactions
    (tra_refno,tra_actual_date,tra_effective_date,tra_fiac_refno,
    tra_tty_srv_code,tra_tty_code,tra_tty_wrk_refno,tra_amount,
    tra_related_reference,tra_related_subreference,tra_fobt_frd_domain, tra_fobt_srv_code, tra_fobt_type, tra_fobt_wrk_refno) 
   VALUES (
    tra_seq.nextval,'10-JAN-2024','10-JAN-2024',l_fiac_refno,
    'SAT','SAT',1,150,
    'RS10000002ZPTS','1','OBJECT TYPES','SAT','RETURN',1)
   RETURNING tra_refno INTO l_ltra_refno;
   
       -- Create the Amendment account
  INSERT INTO parties
    (par_refno,par_type,par_com_company_name,par_org_name,par_marketing_ind,par_fact_type,par_fact_frd_domain,par_fact_srv_code,par_fact_wrk_refno)
  VALUES
    (par_refno_seq.nextval,'ORG','Test Portal Company SAT Users3','Test Portal Company SAT Users3','N','AGENT','PARTY_ACT_TYPES','SYS',1)
  RETURNING par_refno INTO l_par_refno;
  
  create_or_maintain_cde(p_par_refno=>l_par_refno,p_cde_cme_code=>'EMAIL',p_value=>'noreply@necsws.com');
  create_or_maintain_cde(p_par_refno=>l_par_refno,p_cde_cme_code=>'PHONE',p_value=>'07700900321');
  create_or_maintain_address(p_refno=>l_par_refno,p_fao_code=>'PAR',p_adr_address_line_1=>'2 Park Lane',p_adr_address_line_2=>'Garden Village',p_adr_town=>'NORTHTOWN',p_adr_county=>'Northshire',p_adr_postcode=>'RG1 1PB');
  
  -- Note password is created by hashing the username and the password
  INSERT INTO users
     (usr_username,usr_password,usr_password_change_date,usr_force_pw_change,usr_current_ind,usr_name,usr_email_address,usr_wrk_refno,
      usr_int_user_ind,usr_par_refno,usr_per_forename,usr_per_surname,usr_pref_nld_code,usr_tac_signed_date)
  VALUES
     ('PORTAL.SAT.THREE',UPPER (dbms_obfuscation_toolkit.md5 (input => utl_i18n.string_to_raw('PORTAL.SAT.THREE'||'Password1!'))),TRUNC(SYSDATE),'N','Y','Portal SAT THREE','noreply@necsws.com',3,
      'N',l_par_Refno,'Portal User','SAT Three','ENG',TRUNC(SYSDATE));
      
  INSERT INTO role_users
    (rus_rol_code,rus_usr_username)
  (SELECT rus_rol_code,'PORTAL.SAT.THREE'
    FROM role_users
   WHERE rus_usr_username = 'TEMPLATE_SELFSRV_USER');
   
  INSERT INTO user_services
    (use_username, use_service)
   VALUES
    ('PORTAL.SAT.THREE','SAT');    
    
  INSERT INTO parties
    (par_refno,par_type,par_org_name,par_org_frv_oty_code,par_fact_frd_domain,par_fact_srv_code,par_fact_wrk_refno)
  VALUES
    (par_refno_seq.nextval,'ORG','Harry Peterson Partnership','PARTNER','PARTY_ACT_TYPES','SAT',1)
  RETURNING par_refno INTO l_enr_par_refno;
  
  dbms_output.put_line('l_enr_par_refno : ' || l_enr_par_refno );
  
  create_or_maintain_cde(p_par_refno=>l_enr_par_refno,p_cde_cme_code=>'EMAIL',p_value=>'noreply@necsws.com');
  create_or_maintain_cde(p_par_refno=>l_enr_par_refno,p_cde_cme_code=>'PHONE',p_value=>'07700900321');
  create_or_maintain_address(p_refno=>l_enr_par_refno,p_fao_code=>'PAR',p_adr_address_line_1=>'1 Acacia Avenue',p_adr_address_line_2=>'Garden Village',p_adr_town=>'NORTHTOWN',p_adr_county=>'Northshire',p_adr_postcode=>'RG1 1PB');
  
  history_tables_api.snapshot_party( p_par_refno       => l_enr_par_refno
                                       , p_snapshot_src_vn => NULL
                                       , p_parh_version    => l_h_version );
  
  INSERT INTO parties
    (par_refno,par_type,par_org_name,par_org_frv_oty_code,par_fact_frd_domain,par_fact_srv_code,par_fact_wrk_refno)
  VALUES
    (par_refno_seq.nextval,'ORG','Harry Peterson Partnership','PARTNER','PARTY_ACT_TYPES','SAT',1)
  RETURNING par_refno INTO l_aggr_par_refno;
  
  dbms_output.put_line('l_aggr_par_refno : ' || l_aggr_par_refno );
  
  create_or_maintain_cde(p_par_refno=>l_aggr_par_refno,p_cde_cme_code=>'EMAIL',p_value=>'noreply@necsws.com');
  create_or_maintain_cde(p_par_refno=>l_aggr_par_refno,p_cde_cme_code=>'PHONE',p_value=>'07700900321');
  create_or_maintain_address(p_refno=>l_aggr_par_refno,p_fao_code=>'PAR',p_adr_address_line_1=>'1 Acacia Avenue',p_adr_address_line_2=>'Garden Village',p_adr_town=>'NORTHTOWN',p_adr_county=>'Northshire',p_adr_postcode=>'RG1 1PB');
    
  history_tables_api.snapshot_party( p_par_refno       => l_aggr_par_refno
                                       , p_snapshot_src_vn => NULL
                                       , p_parh_version    => l_h_version );

   SELECT usr_par_refno
   INTO l_par_refno_temp
   FROM users
   WHERE usr_username = 'PORTAL.SAT.TWO';
   
   INSERT INTO portal_object_access(POA_PORTAL_PAR_REFNO,POA_OBJECT_TYPE,POA_OBJECT_REFERENCE, POA_CURRENT_IND)
   VALUES(l_par_refno_temp,'TARE_REFNO',l_tare_refno, 'Y');
   
   INSERT INTO tax_returns (tare_refno, tare_reference, tare_srv_code)
   VALUES(tare_seq.nextval,'RS10000001RPGT','SAT')
   RETURNING tare_refno INTO l_tare_refno;

   dbms_output.put_line('l_tare_refno : ' || l_tare_refno );

   INSERT INTO tax_return_versions (trv_tare_refno, trv_version, trv_latest_draft_ind, trv_source, trv_submitted_date, trv_start_date, trv_end_date, trv_enrm_refno, trv_declaration_date, trv_fpay_method, trv_fpay_frd_domain, trv_fpay_wrk_refno, trv_fpay_srv_code)
   VALUES (l_tare_refno,1,'L','P','25-JUL-2024' ,'01-JUL-2024','31-JUL-2024', l_enrm_refno,TRUNC(SYSDATE),'BACS','PAYMENT TYPE',1,'SAT');

   INSERT INTO tax_return_schedules( TRS_REFNO, TRS_ENRM_REFNO, TRS_STRP_REFNO, TRS_PERIOD_START, TRS_PERIOD_END, TRS_TARE_REFNO, TRS_RETURN_STATUS)
   VALUES(TRS_SEQ.NEXTVAL,l_enrm_refno,l_strp_refno,'01-JUL-2024','31-JUL-2024',l_tare_refno,'FILED')
   RETURNING TRS_REFNO INTO l_trs_refno;

   INSERT INTO tax_return_party_links(TRPL_TARE_REFNO, TRPL_TARE_VERSION, TRPL_PARH_PAR_REFNO, TRPL_PARH_VERSION, TRPL_LEAD_IND, TRPL_GROUP_CONTROLLER_IND, TRPL_FLINK_TYPE, TRPL_FLINK_FRD_DOMAIN, TRPL_FLINK_WRK_REFNO, TRPL_FLINK_SRV_CODE)
   VALUES (l_tare_refno, 1, l_aggr_par_refno, 1, 'N', NULL, 'OPERATOR', 'CASEPARTYLINKS', 1, 'SAT');

   INSERT INTO tax_return_party_links(TRPL_TARE_REFNO, TRPL_TARE_VERSION, TRPL_PARH_PAR_REFNO, TRPL_PARH_VERSION, TRPL_LEAD_IND, TRPL_GROUP_CONTROLLER_IND, TRPL_FLINK_TYPE, TRPL_FLINK_FRD_DOMAIN, TRPL_FLINK_WRK_REFNO, TRPL_FLINK_SRV_CODE)
   VALUES (l_tare_refno, 1, l_enr_par_refno, 1, NULL, NULL, 'ENROLMENT', 'CASEPARTYLINKS', 1, 'SAT');

   INSERT INTO trv_location_details(TLD_REFNO, TLD_TAXL_REFNO, TLD_TARE_REFNO, TLD_TARE_VERSION, TLD_START_DATE, TLD_END_DATE, TLD_TAXABLE_TONNAGE, TLD_EXEMPT_TONNAGE, TLD_TAX_DUE, TLD_TAX_CREDITS, TLD_TAX_PAYABLE)
   VALUES(TLD_SEQ.NEXTVAL, l_taxl_refno1, l_tare_refno, 1, '01-JUL-24', '31-JUL-24', 742, 344, 1506.26, 432, 1074.26);

   INSERT INTO trv_location_details(TLD_REFNO, TLD_TAXL_REFNO, TLD_TARE_REFNO, TLD_TARE_VERSION, TLD_START_DATE, TLD_END_DATE, TLD_TAXABLE_TONNAGE, TLD_EXEMPT_TONNAGE, TLD_TAX_DUE, TLD_TAX_CREDITS, TLD_TAX_PAYABLE)
   VALUES(TLD_SEQ.NEXTVAL, l_taxl_refno2, l_tare_refno, 1, '01-JUL-24', '31-JUL-24', 1642, 344, 3333.26, 432, 2901.26);

   INSERT INTO portal_object_access(POA_PORTAL_PAR_REFNO,POA_OBJECT_TYPE,POA_OBJECT_REFERENCE, POA_CURRENT_IND)
   VALUES(l_par_Refno,'TARE_REFNO',l_tare_refno, 'Y');
   
   INSERT INTO schd_type_return_periods(STRP_REFNO, STRP_FPROF_CODE, STRP_FPROF_DOMAIN, STRP_FPROF_SRV_CODE, STRP_FPROF_WRK_REFNO, STRP_START_DATE, STRP_END_DATE, STRP_DESCRIPTION)
   VALUES(STRP_SEQ.NEXTVAL, 'ST4','SCHEDULETYPES','SAT',1,'01-AUG-2024','31-AUG-2024','Period 3')
   RETURNING STRP_REFNO INTO l_strp_refno;

   dbms_output.put_line('l_strp_refno : ' || l_strp_refno );

   INSERT INTO schd_returns_period_breakdown(SRPB_REFNO, SRPB_STRP_REFNO, SRPB_START_DATE, SRPB_END_DATE)
   VALUES( srpb_seq.nextval, l_strp_refno, '01-AUG-2024', '31-AUG-2024');
   
   INSERT INTO enrolment_master (enrm_refno,enrm_registration_ref,enrm_par_refno,enrm_srv_code,enrm_effective_date,enrm_received_date,enrm_start_date,enrm_end_date,enrm_group_name) values 
   (enrm_seq.NEXTVAL,'SAT1000000ZFES',l_enr_par_refno,'SAT','01-AUG-2024','01-AUG-2024','01-AUG-2024',null,'Group 54')
   RETURNING enrm_refno INTO l_enrm_refno;
   
   dbms_output.put_line('l_enrm_refno : ' || l_enrm_refno );
   
   INSERT INTO tax_returns (tare_refno, tare_reference, tare_srv_code)
   VALUES(tare_seq.nextval,'RS11000000ZFEP','SAT')
   RETURNING tare_refno INTO l_tare_refno;
   
   dbms_output.put_line('l_tare_refno : ' || l_tare_refno );  
   
   INSERT INTO portal_object_access(POA_PORTAL_PAR_REFNO, POA_OBJECT_TYPE, POA_OBJECT_REFERENCE)
   VALUES(l_par_Refno,'TARE_REFNO', l_tare_refno);
   
   INSERT INTO tax_return_versions (trv_tare_refno, trv_version, trv_latest_draft_ind, trv_source, trv_submitted_date, trv_start_date, trv_end_date, trv_enrm_refno, trv_declaration_date, trv_fpay_frd_domain, trv_fpay_wrk_refno, trv_fpay_srv_code)
   VALUES (l_tare_refno,1,'L','P','25-JUL-2024' ,'01-JUL-2024','31-JUL-2024',l_enrm_refno,TRUNC(SYSDATE),'PAYMENT TYPE',1,'SAT');
   
   INSERT INTO enrolment_periods (ep_refno,ep_enrm_refno,ep_start_date,ep_end_date,ep_effective_date,ep_status,ep_registration_type,ep_group_ind,ep_non_resident_ind,ep_using_agent_ind,ep_exploit_start,ep_est_quarry,ep_est_sand,ep_est_importation,ep_est_agg_levy,ep_est_exploited,ep_est_exempt,ep_est_export,ep_est_relief,ep_est_crusher,ep_est_other,ep_est_oth_description,ep_est_ere_ind,ep_est_cross_border,ep_take_over_ind,ep_transfer_date,ep_prv_reg_business_name,ep_prv_reg_org_type,ep_prv_reg_adr_refno,ep_prv_reg_retained,ep_prv_reg_no) 
   VALUES (ep_seq.NEXTVAL,l_enrm_refno,'01-AUG-2024',null,'01-AUG-2024','APPROVED','SINGLEREG','N','N','N',TRUNC(SYSDATE),100,200,300,400,500,600,700,800,900,1000,'created via Seed data','N',null,'N',null,null,null,null,null,null)
   RETURNING ep_refno INTO l_ep_refno;
   
   dbms_output.put_line('l_ep_refno : ' || l_ep_refno );
   
   INSERT INTO enrolment_period_parties (epp_ep_refno,epp_par_refno,epp_parh_version,epp_lead_ind,epp_group_controller_ind,epp_flink_type,epp_flink_frd_domain,epp_flink_wrk_refno,epp_flink_srv_code,epp_appoint_date,epp_reg_no,epp_same_corr_adr_ind)
   VALUES (l_ep_refno,l_enr_par_refno,1,null,null,'ENROLMENT','CASEPARTYLINKS',1,'SAT',TRUNC(SYSDATE),null,'Y');
   
   INSERT INTO enrolment_period_parties (epp_ep_refno,epp_par_refno,epp_parh_version,epp_lead_ind,epp_group_controller_ind,epp_flink_type,epp_flink_frd_domain,epp_flink_wrk_refno,epp_flink_srv_code,epp_appoint_date,epp_reg_no,epp_same_corr_adr_ind)   
   VALUES (l_ep_refno,l_aggr_par_refno,1,'N',null,'OPERATOR','CASEPARTYLINKS',1,'SAT',TRUNC(SYSDATE),'null','Y');
   
   l_strp_seq := STRP_SEQ.NEXTVAL;
   l_taxl_refno_seq := TAXL_SEQ.NEXTVAL;

   SELECT strp_refno
   INTO l_strp_seq
   FROM schd_type_return_periods
   WHERE strp_fprof_code = 'ST1'
   AND strp_fprof_domain = 'SCHEDULETYPES'
   AND strp_fprof_srv_code = 'SAT'
   AND strp_fprof_wrk_refno = 1
   AND strp_start_date = TO_DATE('01-APR-2024', 'DD-MON-RRRR HH24:MI:SS');
   
   INSERT INTO tax_return_schedules( TRS_REFNO, TRS_ENRM_REFNO, TRS_STRP_REFNO, TRS_PERIOD_START, TRS_PERIOD_END, TRS_TARE_REFNO,TRS_RETURN_STATUS)
   VALUES(TRS_SEQ.NEXTVAL,l_enrm_refno,l_strp_seq,'01-JUL-2024','31-JUL-2024',l_tare_refno, 'FILED');

   
   INSERT INTO taxable_locations( TAXL_REFNO, TAXL_EPP_PAR_REFNO, TAXL_ENRM_REFNO, TAXL_FTAXL_CODE, TAXL_FTAXL_FRD_DOMAIN, TAXL_FTAXL_WRK_REFNO, TAXL_FTAXL_SRV_CODE, TAXL_NAME, TAXL_START_DATE, TAXL_WEIGHBRIDGE_IND, TAXL_ADR_REFNO, TAXL_CONTACT_NAME, TAXL_EMAIL, TAXL_PHONE, TAXL_MOBILE, TAXL_COUNTRY_OPERATION, TAXL_CROSS_BORDER_IND, TAXL_FLAU_FRD_DOMAIN, TAXL_FLAU_WRK_REFNO, TAXL_FLAU_SRV_CODE)
   VALUES (l_taxl_refno_seq, L_AGGR_PAR_REFNO, l_enrm_refno, 'SITE','TAXL_LOCATION_TYPES',1,'SAT','Site1','01-JUL-2024','N', l_adr_refno, 'Site contact name','donotreply@necsws.com','07411222145','01542548965','SCOTLAND','N','UKLOCALAUTHS',1,'SAT')
   RETURNING TAXL_REFNO INTO l_taxl_refno1;

   l_taxl_refno_seq := TAXL_SEQ.NEXTVAL;
   
   INSERT INTO taxable_locations( TAXL_REFNO, TAXL_EPP_PAR_REFNO, TAXL_ENRM_REFNO, TAXL_FTAXL_CODE, TAXL_FTAXL_FRD_DOMAIN, TAXL_FTAXL_WRK_REFNO, TAXL_FTAXL_SRV_CODE, TAXL_NAME, TAXL_START_DATE, TAXL_WEIGHBRIDGE_IND, TAXL_ADR_REFNO, TAXL_CONTACT_NAME, TAXL_EMAIL, TAXL_PHONE, TAXL_MOBILE, TAXL_COUNTRY_OPERATION, TAXL_CROSS_BORDER_IND, TAXL_FLAU_FRD_DOMAIN, TAXL_FLAU_WRK_REFNO, TAXL_FLAU_SRV_CODE)
   VALUES (l_taxl_refno_seq, L_AGGR_PAR_REFNO, l_enrm_refno, 'SITE','TAXL_LOCATION_TYPES',1,'SAT','Site2','01-JUL-2024','N', l_adr_refno, 'Site contact name','donotreply@necsws.com','07411222145','01542548965','SCOTLAND','N','UKLOCALAUTHS',1,'SAT')
   RETURNING TAXL_REFNO INTO l_taxl_refno2;
    
   SELECT strp_refno
   INTO l_strp_seq
   FROM schd_type_return_periods
   WHERE strp_fprof_code = 'ST1'
   AND strp_fprof_domain = 'SCHEDULETYPES'
   AND strp_fprof_srv_code = 'SAT'
   AND strp_fprof_wrk_refno = 1
   AND strp_start_date = '01-JUL-2024';
   
   INSERT INTO tax_return_schedules( TRS_REFNO, TRS_ENRM_REFNO, TRS_STRP_REFNO, TRS_PERIOD_START, TRS_PERIOD_END)
   VALUES(TRS_SEQ.NEXTVAL,l_enrm_refno,l_strp_seq,'01-AUG-2024','31-AUG-2024');


   INSERT INTO tax_returns (tare_refno, tare_reference, tare_srv_code)
   VALUES(tare_seq.nextval,'RS11000000ZFES','SAT')
   RETURNING tare_refno INTO l_tare_refno;
   
   dbms_output.put_line('l_tare_refno : ' || l_tare_refno );  
   
   INSERT INTO tax_return_versions (trv_tare_refno, trv_version, trv_latest_draft_ind, trv_source, trv_submitted_date, trv_start_date, trv_end_date, trv_enrm_refno, trv_declaration_date, trv_fpay_frd_domain, trv_fpay_wrk_refno, trv_fpay_srv_code)
   VALUES (l_tare_refno,1,'D','P','25-JUL-2024' ,'01-JUL-2024','31-JUL-2024',l_enrm_refno,TRUNC(SYSDATE),'PAYMENT TYPE',1,'SAT');
      
   INSERT INTO cases (
    case_refno,case_reference,
    case_caty_type,case_caty_srv_code,case_caty_wrk_refno,
    case_cast_status,case_casr_reason,
    case_automatic_ind,case_fcas_source,case_fcas_frd_domain,case_fcas_wrk_refno,case_fcas_srv_code,
    case_receipt_date,case_all_information_date,
    case_fobt_type,case_fobt_frd_domain,case_fobt_wrk_refno,case_fobt_srv_code,case_related_reference
  ) VALUES (
    case_seq.nextval,'PORTAL.SAT1000000ZFES',
    'ENROLMENT','SAT',1,
    'OPEN','ENROLMENT TO PROCESS',
    'Y','ONLINEFORM','CASESOURCES',1,'SAT',
    SYSDATE,NULL,
    'ENROLMENT','CASEOBJECTTYPES',1,'SAT','SAT1000000ZFES'
  ) 
  RETURNING case_refno INTO l_case_refno;
  
  dbms_output.put_line('l_case_refno : ' || l_case_refno );
  
  INSERT INTO portal_object_access
  (POA_PORTAL_PAR_REFNO, POA_OBJECT_TYPE, POA_OBJECT_REFERENCE)
  VALUES
  (l_par_Refno,'ENRM_REFNO', l_enrm_refno);

   INSERT INTO tax_return_schedule_types(TRST_REFNO, TRST_ENRM_REFNO, TRST_START_DATE, TRST_END_DATE, TRST_FSCH_CODE, TRST_FSCH_FRD_DOMAIN, TRST_FSCH_WRK_REFNO, TRST_FSCH_SRV_CODE)
   VALUES (TRST_SEQ.NEXTVAL, l_enrm_refno, '01-JUN-24', NULL, 'ST4', 'SCHEDULETYPES', 1, 'SAT');
   
   SELECT strp_refno
   INTO l_strp_seq
   FROM schd_type_return_periods
   WHERE strp_fprof_code = 'ST4'
   AND strp_fprof_domain = 'SCHEDULETYPES'
   AND strp_fprof_srv_code = 'SAT'
   AND strp_fprof_wrk_refno = 1
   AND strp_start_date = '01-JUN-2024'; 
   dbms_output.put_line('l_strp_refno : ' || l_strp_refno );

   INSERT INTO schd_returns_period_breakdown(SRPB_REFNO, SRPB_STRP_REFNO, SRPB_START_DATE, SRPB_END_DATE)
   VALUES( srpb_seq.nextval, l_strp_refno, '01-JUN-2024', '30-JUN-2024');
   
   INSERT INTO tax_returns (tare_refno, tare_reference, tare_srv_code)
   VALUES(tare_seq.nextval,'RS10000001RPTQ','SAT')
   RETURNING tare_refno INTO l_tare_refno;

   dbms_output.put_line('l_tare_refno : ' || l_tare_refno );

   INSERT INTO tax_return_versions (trv_tare_refno, trv_version, trv_latest_draft_ind, trv_source, trv_submitted_date, trv_start_date, trv_end_date, trv_enrm_refno, trv_declaration_date, trv_fpay_method, trv_fpay_frd_domain, trv_fpay_wrk_refno, trv_fpay_srv_code)
   VALUES (l_tare_refno,1,'L','P','25-JUN-2024','01-JUN-2024','30-JUN-2024', l_enrm_refno,TRUNC(SYSDATE),'BACS','PAYMENT TYPE',1,'SAT');

   INSERT INTO tax_return_schedules( TRS_REFNO, TRS_ENRM_REFNO, TRS_STRP_REFNO, TRS_PERIOD_START, TRS_PERIOD_END, TRS_TARE_REFNO, TRS_RETURN_STATUS)
   VALUES(TRS_SEQ.NEXTVAL,l_enrm_refno,l_strp_refno,'01-JUN-2024','30-JUN-2024',l_tare_refno,'FILED')
   RETURNING TRS_REFNO INTO l_trs_refno;

   INSERT INTO tax_return_party_links(TRPL_TARE_REFNO, TRPL_TARE_VERSION, TRPL_PARH_PAR_REFNO, TRPL_PARH_VERSION, TRPL_LEAD_IND, TRPL_GROUP_CONTROLLER_IND, TRPL_FLINK_TYPE, TRPL_FLINK_FRD_DOMAIN, TRPL_FLINK_WRK_REFNO, TRPL_FLINK_SRV_CODE)
   VALUES (l_tare_refno, 1, l_aggr_par_refno, 1, 'N', NULL, 'OPERATOR', 'CASEPARTYLINKS', 1, 'SAT');

   INSERT INTO tax_return_party_links(TRPL_TARE_REFNO, TRPL_TARE_VERSION, TRPL_PARH_PAR_REFNO, TRPL_PARH_VERSION, TRPL_LEAD_IND, TRPL_GROUP_CONTROLLER_IND, TRPL_FLINK_TYPE, TRPL_FLINK_FRD_DOMAIN, TRPL_FLINK_WRK_REFNO, TRPL_FLINK_SRV_CODE)
   VALUES (l_tare_refno, 1, l_enr_par_refno, 1, NULL, NULL, 'ENROLMENT', 'CASEPARTYLINKS', 1, 'SAT');

   INSERT INTO trv_location_details(TLD_REFNO, TLD_TAXL_REFNO, TLD_TARE_REFNO, TLD_TARE_VERSION, TLD_START_DATE, TLD_END_DATE, TLD_TAXABLE_TONNAGE, TLD_EXEMPT_TONNAGE, TLD_TAX_DUE, TLD_TAX_CREDITS, TLD_TAX_PAYABLE)
   VALUES(TLD_SEQ.NEXTVAL, l_taxl_refno1, l_tare_refno, 1, '01-JUN-24', '30-JUN-24', 431.00, 344.00, 874.93, 759.00, 115.93);

   INSERT INTO trv_location_details(TLD_REFNO, TLD_TAXL_REFNO, TLD_TARE_REFNO, TLD_TARE_VERSION, TLD_START_DATE, TLD_END_DATE, TLD_TAXABLE_TONNAGE, TLD_EXEMPT_TONNAGE, TLD_TAX_DUE, TLD_TAX_CREDITS, TLD_TAX_PAYABLE)
   VALUES(TLD_SEQ.NEXTVAL, l_taxl_refno2, l_tare_refno, 1, '01-JUN-24', '30-JUN-24', 786.00, 1118.00, 1595.58, 1191, 404.58);

   INSERT INTO portal_object_access(POA_PORTAL_PAR_REFNO,POA_OBJECT_TYPE,POA_OBJECT_REFERENCE, POA_CURRENT_IND)
   VALUES(l_par_Refno,'TARE_REFNO',l_tare_refno, 'Y');

  ---Creating data for SAT
  
  -- Create the Main account
  INSERT INTO parties
  (par_refno,par_type,par_com_company_name,par_org_name,par_marketing_ind,par_fact_type,par_fact_frd_domain,par_fact_srv_code,par_fact_wrk_refno,par_org_frv_oty_code)
  VALUES
    (par_refno_seq.nextval,'ORG','Test Portal Company SAT Users4','Test Portal Company SAT Users4','N','TAXPAYER','PARTY_ACT_TYPES','SYS',1,'PARTNER')
  RETURNING par_refno INTO l_par_refno;
  
  create_or_maintain_cde(p_par_refno=>l_par_refno,p_cde_cme_code=>'EMAIL',p_value=>'noreply@necsws.com');
  create_or_maintain_cde(p_par_refno=>l_par_refno,p_cde_cme_code=>'PHONE',p_value=>'07700900321');
  create_or_maintain_address(p_refno=>l_par_refno,p_fao_code=>'PAR',p_adr_address_line_1=>'2 Park Lane',p_adr_address_line_2=>'Garden Village',p_adr_town=>'NORTHTOWN',p_adr_county=>'Northshire',p_adr_postcode=>'RG1 1PB');
        
  -- Note password is created by hashing the username and the password
  INSERT INTO users
     (usr_username,usr_password,usr_password_change_date,usr_force_pw_change,usr_current_ind,usr_name,usr_email_address,usr_wrk_refno,
      usr_int_user_ind,usr_par_refno,usr_per_forename,usr_per_surname,usr_pref_nld_code,usr_tac_signed_date)
  VALUES
     ('PORTAL.SAT.TAXPAYER',UPPER (dbms_obfuscation_toolkit.md5 (input => utl_i18n.string_to_raw('PORTAL.SAT.TAXPAYER'||'Password1!'))),TRUNC(SYSDATE),'N','Y','Portal SAT Taxpayer','noreply@necsws.com',3,
      'N',l_par_Refno,'Portal User','SAT Taxpayer','ENG',TRUNC(SYSDATE));
      
  INSERT INTO role_users
    (rus_rol_code,rus_usr_username)
  (SELECT rus_rol_code,'PORTAL.SAT.TAXPAYER'
    FROM role_users
   WHERE rus_usr_username = 'TEMPLATE_SELFSRV_USER');
   
   INSERT INTO user_services
    (use_username, use_service)
   VALUES
    ('PORTAL.SAT.TAXPAYER','SAT');
    
   --creating enrolment party 
   INSERT INTO parties
    (par_refno,par_type,par_org_name,par_org_frv_oty_code,par_fact_frd_domain,par_fact_srv_code,par_fact_wrk_refno)
  VALUES
    (par_refno_seq.nextval,'ORG','Jim and James Group','PARTNER','PARTY_ACT_TYPES','SAT',1)
  RETURNING par_refno INTO l_enr_par_refno;
  
  dbms_output.put_line('l_enr_par_refno : ' || l_enr_par_refno );
  
  create_or_maintain_cde(p_par_refno=>l_enr_par_refno,p_cde_cme_code=>'EMAIL',p_value=>'noreply@necsws.com');
  create_or_maintain_cde(p_par_refno=>l_enr_par_refno,p_cde_cme_code=>'PHONE',p_value=>'07700900321');
  create_or_maintain_address(p_refno=>l_enr_par_refno,p_fao_code=>'PAR',p_adr_address_line_1=>'1 Acacia Avenue',p_adr_address_line_2=>'Garden Village',p_adr_town=>'NORTHTOWN',p_adr_county=>'Northshire',p_adr_postcode=>'RG1 1PB');
  
  history_tables_api.snapshot_party( p_par_refno       => l_enr_par_refno
                                       , p_snapshot_src_vn => NULL
                                       , p_parh_version    => l_h_version );
  
  --creating aggregate party
  INSERT INTO parties
    (par_refno,par_type,par_org_name,par_org_frv_oty_code,par_fact_frd_domain,par_fact_srv_code,par_fact_wrk_refno)
  VALUES
    (par_refno_seq.nextval,'ORG','Jim and James Group','PARTNER','PARTY_ACT_TYPES','SAT',1)
  RETURNING par_refno INTO l_aggr_par_refno;
  
  dbms_output.put_line('l_aggr_par_refno : ' || l_aggr_par_refno );
  
  create_or_maintain_cde(p_par_refno=>l_aggr_par_refno,p_cde_cme_code=>'EMAIL',p_value=>'noreply@necsws.com');
  create_or_maintain_cde(p_par_refno=>l_aggr_par_refno,p_cde_cme_code=>'PHONE',p_value=>'07700900321');
  create_or_maintain_address(p_refno=>l_aggr_par_refno,p_fao_code=>'PAR',p_adr_address_line_1=>'1 Acacia Avenue',p_adr_address_line_2=>'Garden Village',p_adr_town=>'NORTHTOWN',p_adr_county=>'Northshire',p_adr_postcode=>'RG1 1PB');
    
  history_tables_api.snapshot_party( p_par_refno       => l_aggr_par_refno
                                       , p_snapshot_src_vn => NULL
                                       , p_parh_version    => l_h_version );
  
  
   
  --Inerting into enrolment_master
   INSERT INTO enrolment_master (enrm_refno,enrm_registration_ref,enrm_par_refno,enrm_srv_code,enrm_effective_date,enrm_received_date,enrm_start_date,enrm_end_date,enrm_group_name) VALUES 
   (enrm_seq.NEXTVAL,'SAT1000000KGLM',l_enr_par_refno,'SAT','01-JUN-2024','01-JUN-2024','01-JUN-2024',null,'Group 54')
   returning enrm_refno INTO l_enrm_refno;
   
   dbms_output.put_line('l_enrm_refno : ' || l_enrm_refno );
   
   INSERT INTO ENROLMENT_PERIODS (ep_refno,ep_enrm_refno,ep_start_date,ep_end_date,ep_effective_date,ep_status,ep_registration_type,ep_group_ind,ep_non_resident_ind,ep_using_agent_ind,ep_exploit_start,ep_est_quarry,ep_est_sand,ep_est_importation,ep_est_agg_levy,ep_est_exploited,ep_est_exempt,ep_est_export,ep_est_relief,ep_est_crusher,ep_est_other,ep_est_oth_description,ep_est_ere_ind,ep_est_cross_border,ep_take_over_ind,ep_transfer_date,ep_prv_reg_business_name,ep_prv_reg_org_type,ep_prv_reg_adr_refno,ep_prv_reg_retained,ep_prv_reg_no) 
   VALUES (ep_seq.NEXTVAL,l_enrm_refno,'01-JUN-2024',null,'01-JUN-2024','APPROVED','SINGLEREG','N','N','N',TRUNC(SYSDATE),100,200,300,400,500,600,700,800,900,1000,'created via Seed data','N',null,'N',null,null,null,null,null,null)
   RETURNING ep_refno INTO l_ep_refno;
   
   dbms_output.put_line('l_ep_refno : ' || l_ep_refno );
   
   INSERT INTO ENROLMENT_PERIOD_PARTIES (epp_ep_refno,epp_par_refno,epp_parh_version,epp_lead_ind,epp_group_controller_ind,epp_flink_type,epp_flink_frd_domain,epp_flink_wrk_refno,epp_flink_srv_code,epp_appoint_date,epp_reg_no,epp_same_corr_adr_ind)
   VALUES (l_ep_refno,l_enr_par_refno,1,null,null,'ENROLMENT','CASEPARTYLINKS',1,'SAT',TRUNC(SYSDATE),null,'Y');
   
   INSERT INTO ENROLMENT_PERIOD_PARTIES (epp_ep_refno,epp_par_refno,epp_parh_version,epp_lead_ind,epp_group_controller_ind,epp_flink_type,epp_flink_frd_domain,epp_flink_wrk_refno,epp_flink_srv_code,epp_appoint_date,epp_reg_no,epp_same_corr_adr_ind)   
   VALUES (l_ep_refno,l_aggr_par_refno,1,'N',null,'OPERATOR','CASEPARTYLINKS',1,'SAT',TRUNC(SYSDATE),'null','Y');

   l_taxl_refno_seq := TAXL_SEQ.NEXTVAL;
   
   INSERT INTO taxable_locations( TAXL_REFNO, TAXL_EPP_PAR_REFNO, TAXL_ENRM_REFNO, TAXL_FTAXL_CODE, TAXL_FTAXL_FRD_DOMAIN, TAXL_FTAXL_WRK_REFNO, TAXL_FTAXL_SRV_CODE, TAXL_NAME, TAXL_START_DATE, TAXL_WEIGHBRIDGE_IND, TAXL_ADR_REFNO, TAXL_CONTACT_NAME, TAXL_EMAIL, TAXL_PHONE, TAXL_MOBILE, TAXL_COUNTRY_OPERATION, TAXL_CROSS_BORDER_IND, TAXL_FLAU_FRD_DOMAIN, TAXL_FLAU_WRK_REFNO, TAXL_FLAU_SRV_CODE)
   VALUES (l_taxl_refno_seq, L_AGGR_PAR_REFNO, l_enrm_refno, 'SITE','TAXL_LOCATION_TYPES',1,'SAT','Site1','01-JUN-2024','N', l_adr_refno, 'Site contact name','donotreply@necsws.com','07411222145','01542548965','SCOTLAND','N','UKLOCALAUTHS',1,'SAT')
   RETURNING TAXL_REFNO INTO l_taxl_refno1;

   INSERT INTO tax_return_schedule_types(TRST_REFNO, TRST_ENRM_REFNO, TRST_START_DATE, TRST_END_DATE, TRST_FSCH_CODE, TRST_FSCH_FRD_DOMAIN, TRST_FSCH_WRK_REFNO, TRST_FSCH_SRV_CODE)
   VALUES (TRST_SEQ.NEXTVAL, l_enrm_refno, '01-JUN-24', NULL, 'ST3', 'SCHEDULETYPES', 1, 'SAT');
   
   INSERT INTO cases (
    case_refno,case_reference,
    case_caty_type,case_caty_srv_code,case_caty_wrk_refno,
    case_cast_status,case_casr_reason,
    case_automatic_ind,case_fcas_source,case_fcas_frd_domain,case_fcas_wrk_refno,case_fcas_srv_code,
    case_receipt_date,case_all_information_date,
    case_fobt_type,case_fobt_frd_domain,case_fobt_wrk_refno,case_fobt_srv_code,case_related_reference
  ) VALUES (
    case_seq.nextval,'PORTAL.SAT1000000KGLM',
    'ENROLMENT','SAT',1,
    'OPEN','ENROLMENT TO PROCESS',
    'Y','ONLINEFORM','CASESOURCES',1,'SAT',
    SYSDATE,NULL,
    'ENROLMENT','CASEOBJECTTYPES',1,'SAT','SAT1000000KGLM'
  ) 
  returning case_refno INTO l_case_refno;
  
  dbms_output.put_line('l_case_refno : ' || l_case_refno );
  
  INSERT INTO portal_object_access
  (POA_PORTAL_PAR_REFNO, POA_OBJECT_TYPE, POA_OBJECT_REFERENCE)
  VALUES
  (l_par_Refno,'ENRM_REFNO', l_enrm_refno);
   
   INSERT INTO tax_returns (tare_refno, tare_reference, tare_srv_code)
   VALUES(tare_seq.nextval,'RS10000001GLVD','SAT')
   RETURNING tare_refno INTO l_tare_refno;

   dbms_output.put_line('l_tare_refno : ' || l_tare_refno );

   INSERT INTO tax_return_versions (trv_tare_refno, trv_version, trv_latest_draft_ind, trv_source, trv_submitted_date, trv_start_date, trv_end_date, trv_enrm_refno, trv_declaration_date, trv_fpay_method, trv_fpay_frd_domain, trv_fpay_wrk_refno, trv_fpay_srv_code)
   VALUES (l_tare_refno,1,'L','P','28-FEB-2025','01-DEC-2024','28-FEB-2025', l_enrm_refno,TRUNC(SYSDATE),'BACS','PAYMENT TYPE',1,'SAT');
    
   SELECT strp_refno
   INTO l_strp_seq
   FROM schd_type_return_periods
   WHERE strp_fprof_code = 'ST3'
   AND strp_fprof_domain = 'SCHEDULETYPES'
   AND strp_fprof_srv_code = 'SAT'
   AND strp_fprof_wrk_refno = 1
   AND strp_start_date = '01-DEC-24';

   INSERT INTO schd_returns_period_breakdown(SRPB_REFNO, SRPB_STRP_REFNO, SRPB_START_DATE, SRPB_END_DATE)
   VALUES( srpb_seq.nextval, l_strp_seq, '01-DEC-24', '31-DEC-24');

   INSERT INTO schd_returns_period_breakdown(SRPB_REFNO, SRPB_STRP_REFNO, SRPB_START_DATE, SRPB_END_DATE)
   VALUES( srpb_seq.nextval, l_strp_seq, '01-JAN-2025', '28-FEB-2025');

   INSERT INTO tax_return_schedules( TRS_REFNO, TRS_ENRM_REFNO, TRS_STRP_REFNO, TRS_PERIOD_START, TRS_PERIOD_END, TRS_TARE_REFNO, TRS_RETURN_STATUS)
   VALUES(TRS_SEQ.NEXTVAL,l_enrm_refno,l_strp_seq,'01-DEC-2024','28-FEB-2025',l_tare_refno,'FILED')
   RETURNING TRS_REFNO INTO l_trs_refno;

   INSERT INTO tax_return_party_links(TRPL_TARE_REFNO, TRPL_TARE_VERSION, TRPL_PARH_PAR_REFNO, TRPL_PARH_VERSION, TRPL_LEAD_IND, TRPL_GROUP_CONTROLLER_IND, TRPL_FLINK_TYPE, TRPL_FLINK_FRD_DOMAIN, TRPL_FLINK_WRK_REFNO, TRPL_FLINK_SRV_CODE)
   VALUES (l_tare_refno, 1, l_aggr_par_refno, 1, 'N', NULL, 'OPERATOR', 'CASEPARTYLINKS', 1, 'SAT');

   INSERT INTO tax_return_party_links(TRPL_TARE_REFNO, TRPL_TARE_VERSION, TRPL_PARH_PAR_REFNO, TRPL_PARH_VERSION, TRPL_LEAD_IND, TRPL_GROUP_CONTROLLER_IND, TRPL_FLINK_TYPE, TRPL_FLINK_FRD_DOMAIN, TRPL_FLINK_WRK_REFNO, TRPL_FLINK_SRV_CODE)
   VALUES (l_tare_refno, 1, l_enr_par_refno, 1, NULL, NULL, 'ENROLMENT', 'CASEPARTYLINKS', 1, 'SAT');

   INSERT INTO trv_location_details(TLD_REFNO, TLD_TAXL_REFNO, TLD_TARE_REFNO, TLD_TARE_VERSION, TLD_START_DATE, TLD_END_DATE, TLD_TAXABLE_TONNAGE, TLD_EXEMPT_TONNAGE, TLD_TAX_DUE, TLD_TAX_CREDITS, TLD_TAX_PAYABLE)
   VALUES(TLD_SEQ.NEXTVAL, l_taxl_refno1, l_tare_refno, 1,'01-DEC-2024','31-DEC-24', 1000.00, 20.00, 2030.00, 0.00, 2030.00) RETURNING TLD_REFNO INTO l_tld_refno;

   INSERT INTO trd_location_breakdown(TLB_TLD_REFNO,TLB_FLBD_CODE,TLB_FLBD_FRD_DOMAIN,TLB_FLBD_WRK_REFNO,TLB_FLBD_SRV_CODE,TLB_TONNAGE,TLB_RATE,TLB_WATER_TONNAGE,TLB_MIXED_IND,TLB_TAX_TOTAL,TLB_FATY_CODE,TLB_FATY_FRD_DOMAIN,TLB_FATY_WRK_REFNO,TLB_FATY_SRV_CODE,TLB_FAAT_CODE,TLB_FAAT_FRD_DOMAIN,TLB_FAAT_WRK_REFNO,TLB_FAAT_SRV_CODE,TLB_REL_TARE_REFNO,TLB_REL_PER_START,TLB_REL_PER_END,TLB_REFNO)
   values (l_tld_refno,'TAAG','RETURNATTRIBUTES',1,'SAT',1100,2.03,100,'N',2030,'SAND','AGGREGATE TYPE',1,'SAT','CONSTRUCT','COMMEXPLOITREASON',1,'SAT',null,null,null,TLB_SEQ.NEXTVAL);

   INSERT INTO trd_location_breakdown(TLB_TLD_REFNO,TLB_FLBD_CODE,TLB_FLBD_FRD_DOMAIN,TLB_FLBD_WRK_REFNO,TLB_FLBD_SRV_CODE,TLB_TONNAGE,TLB_RATE,TLB_WATER_TONNAGE,TLB_MIXED_IND,TLB_TAX_TOTAL,TLB_FATY_CODE,TLB_FATY_FRD_DOMAIN,TLB_FATY_WRK_REFNO,TLB_FATY_SRV_CODE,TLB_FAAT_CODE,TLB_FAAT_FRD_DOMAIN,TLB_FAAT_WRK_REFNO,TLB_FAAT_SRV_CODE,TLB_REL_TARE_REFNO,TLB_REL_PER_START,TLB_REL_PER_END,TLB_REFNO)
   values (l_tld_refno,'EXAG','RETURNATTRIBUTES',1,'SAT',20,null,null,'N',null,'ROCK','AGGREGATE TYPE',1,'SAT','CWOSOCLS','EXEMPTREASON',1,'SAT',null,null,null,TLB_SEQ.NEXTVAL);

   INSERT INTO trd_location_breakdown(TLB_TLD_REFNO,TLB_FLBD_CODE,TLB_FLBD_FRD_DOMAIN,TLB_FLBD_WRK_REFNO,TLB_FLBD_SRV_CODE,TLB_TONNAGE,TLB_RATE,TLB_WATER_TONNAGE,TLB_MIXED_IND,TLB_TAX_TOTAL,TLB_FATY_CODE,TLB_FATY_FRD_DOMAIN,TLB_FATY_WRK_REFNO,TLB_FATY_SRV_CODE,TLB_FAAT_CODE,TLB_FAAT_FRD_DOMAIN,TLB_FAAT_WRK_REFNO,TLB_FAAT_SRV_CODE,TLB_REL_TARE_REFNO,TLB_REL_PER_START,TLB_REL_PER_END,TLB_REFNO)
   values (l_tld_refno,'TACR','RETURNATTRIBUTES',1,'SAT',null,2.03,null,'N',null,'SAND','AGGREGATE TYPE',1,'SAT','EXCEPTED','TAXCREDITREASON',1,'SAT',null,null,null,TLB_SEQ.NEXTVAL);

   INSERT INTO trv_location_details(TLD_REFNO, TLD_TAXL_REFNO, TLD_TARE_REFNO, TLD_TARE_VERSION, TLD_START_DATE, TLD_END_DATE, TLD_TAXABLE_TONNAGE, TLD_EXEMPT_TONNAGE, TLD_TAX_DUE, TLD_TAX_CREDITS, TLD_TAX_PAYABLE)
   VALUES(TLD_SEQ.NEXTVAL, l_taxl_refno1, l_tare_refno, 1,'01-JAN-2025', '28-FEB-2025', 1000.00, 50.00, 2100.00, 0.00, 2100.00) RETURNING TLD_REFNO INTO l_tld_refno;

   INSERT INTO trd_location_breakdown(TLB_TLD_REFNO,TLB_FLBD_CODE,TLB_FLBD_FRD_DOMAIN,TLB_FLBD_WRK_REFNO,TLB_FLBD_SRV_CODE,TLB_TONNAGE,TLB_RATE,TLB_WATER_TONNAGE,TLB_MIXED_IND,TLB_TAX_TOTAL,TLB_FATY_CODE,TLB_FATY_FRD_DOMAIN,TLB_FATY_WRK_REFNO,TLB_FATY_SRV_CODE,TLB_FAAT_CODE,TLB_FAAT_FRD_DOMAIN,TLB_FAAT_WRK_REFNO,TLB_FAAT_SRV_CODE,TLB_REL_TARE_REFNO,TLB_REL_PER_START,TLB_REL_PER_END,TLB_REFNO)
   values (l_tld_refno,'TAAG','RETURNATTRIBUTES',1,'SAT',1100,2.10,100,'N',2100,'SAND','AGGREGATE TYPE',1,'SAT','CONSTRUCT','COMMEXPLOITREASON',1,'SAT',null,null,null,TLB_SEQ.NEXTVAL);

   INSERT INTO trd_location_breakdown(TLB_TLD_REFNO,TLB_FLBD_CODE,TLB_FLBD_FRD_DOMAIN,TLB_FLBD_WRK_REFNO,TLB_FLBD_SRV_CODE,TLB_TONNAGE,TLB_RATE,TLB_WATER_TONNAGE,TLB_MIXED_IND,TLB_TAX_TOTAL,TLB_FATY_CODE,TLB_FATY_FRD_DOMAIN,TLB_FATY_WRK_REFNO,TLB_FATY_SRV_CODE,TLB_FAAT_CODE,TLB_FAAT_FRD_DOMAIN,TLB_FAAT_WRK_REFNO,TLB_FAAT_SRV_CODE,TLB_REL_TARE_REFNO,TLB_REL_PER_START,TLB_REL_PER_END,TLB_REFNO)
   values (l_tld_refno,'EXAG','RETURNATTRIBUTES',1,'SAT',50,null,null,'N',null,'ROCK','AGGREGATE TYPE',1,'SAT','CWOSOCLS','EXEMPTREASON',1,'SAT',null,null,null,TLB_SEQ.NEXTVAL);

   INSERT INTO trd_location_breakdown(TLB_TLD_REFNO,TLB_FLBD_CODE,TLB_FLBD_FRD_DOMAIN,TLB_FLBD_WRK_REFNO,TLB_FLBD_SRV_CODE,TLB_TONNAGE,TLB_RATE,TLB_WATER_TONNAGE,TLB_MIXED_IND,TLB_TAX_TOTAL,TLB_FATY_CODE,TLB_FATY_FRD_DOMAIN,TLB_FATY_WRK_REFNO,TLB_FATY_SRV_CODE,TLB_FAAT_CODE,TLB_FAAT_FRD_DOMAIN,TLB_FAAT_WRK_REFNO,TLB_FAAT_SRV_CODE,TLB_REL_TARE_REFNO,TLB_REL_PER_START,TLB_REL_PER_END,TLB_REFNO)
   values (l_tld_refno,'TACR','RETURNATTRIBUTES',1,'SAT',null,2.10,null,'N',null,'SAND','AGGREGATE TYPE',1,'SAT','EXCEPTED','TAXCREDITREASON',1,'SAT',null,null,null,TLB_SEQ.NEXTVAL);

   INSERT INTO portal_object_access(POA_PORTAL_PAR_REFNO,POA_OBJECT_TYPE,POA_OBJECT_REFERENCE, POA_CURRENT_IND)
   VALUES(l_par_Refno,'TARE_REFNO',l_tare_refno, 'Y');
   
    --*********************************
    -- Create the Financial accounts for the PORTAL.SAT.TAXPAYER account
    --*********************************
   INSERT INTO financial_accounts
     (fiac_refno,fiac_reference,fiac_wrk_refno,fiac_srv_code,fiac_suspense_ind)
   values
     (fiac_seq.nextval,'RS10000001GLVD',1,'SAT',NULL)
   RETURNING fiac_refno INTO l_fiac_refno;

   UPDATE tax_returns
   SET tare_fiac_refno = l_fiac_refno
   WHERE tare_refno = l_tare_refno;
    
   INSERT INTO fiac_party_links
     (fpli_par_refno,fpli_fiac_refno,
    fpli_ffpl_type,fpli_ffpl_frd_domain,fpli_ffpl_srv_code,fpli_ffpl_wrk_refno,fpli_authority_ind)
   VALUES (
    l_enr_par_refno,l_fiac_refno,'LIABLE','FIACPARTYLINKS','SAT',1,'N');
    
   INSERT INTO transactions
    (tra_refno,tra_actual_date,tra_effective_date,tra_fiac_refno,
    tra_tty_srv_code,tra_tty_code,tra_tty_wrk_refno,tra_amount,
    tra_related_reference,tra_related_subreference,tra_fobt_frd_domain, tra_fobt_srv_code, tra_fobt_type, tra_fobt_wrk_refno) 
   VALUES (
    tra_seq.nextval,'28-FEB-2025','28-FEB-2025',l_fiac_refno,
    'SAT','SAT',1,4130,
    'RS10000001GLVD','1','OBJECT TYPES','SAT','RETURN',1)
   RETURNING tra_refno INTO l_ltra_refno;

   l_case_refno := case_seq.nextval;
   
   INSERT INTO cases (
    case_refno,case_reference,
    case_caty_type,case_caty_srv_code,case_caty_wrk_refno,
    case_cast_status,case_casr_reason,
    case_automatic_ind,case_fcas_source,case_fcas_frd_domain,case_fcas_wrk_refno,case_fcas_srv_code,
    case_receipt_date,case_all_information_date,
    case_fobt_type,case_fobt_frd_domain,case_fobt_wrk_refno,case_fobt_srv_code,case_related_reference
  ) VALUES (
    l_case_refno,'PORTAL.CMSA000'||l_case_refno,
    'RETURN','SAT',1,
    'OPEN','RETURNCHECK',
    'Y','DASHBOARD','CASESOURCES',1,'SAT',
    SYSDATE,NULL,
    'RETURN','CASEOBJECTTYPES',1,'SAT','RS10000001GLVD'
  );

   dbms_output.put_line('l_case_refno : ' || l_case_refno );

  INSERT INTO case_return_links (
    crli_tare_refno, crli_case_refno
  ) VALUES (
    l_tare_refno,l_case_refno
  );

   l_case_refno := case_seq.nextval;
   
   INSERT INTO cases (
    case_refno,case_reference,
    case_caty_type,case_caty_srv_code,case_caty_wrk_refno,
    case_cast_status,case_casr_reason,
    case_automatic_ind,case_fcas_source,case_fcas_frd_domain,case_fcas_wrk_refno,case_fcas_srv_code,
    case_receipt_date,case_all_information_date,
    case_fobt_type,case_fobt_frd_domain,case_fobt_wrk_refno,case_fobt_srv_code,case_related_reference
  ) VALUES (
    l_case_refno,'PORTAL.CMSA000'||l_case_refno,
    'AMENDMENT','SAT',1,
    'AWAITING AUTHORISATION','AMENDMENTCHECK',
    'Y','DASHBOARD','CASESOURCES',1,'SAT',
    SYSDATE,NULL,
    'RETURN','CASEOBJECTTYPES',1,'SAT','RS10000001GLVD'
  );

   dbms_output.put_line('l_case_refno : ' || l_case_refno );

  INSERT INTO case_return_links (
    crli_tare_refno, crli_case_refno
  ) VALUES (
    l_tare_refno,l_case_refno
  );
    
  COMMIT;
END;
/
