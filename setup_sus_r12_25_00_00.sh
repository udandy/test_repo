#! /bin/ksh

#********************************************************************************************
#    Author     : Priya Garde
#    Created    : 18-June-2012
#    Name       : setup_sus_r12_25_00_00.sh
#    Purpose    : Shell Script for deployment of SUS R12 Drop 1
#    Assumption : None.
#    Notes      :
#
#    -------------------------------------------------------------------------------
#    Modification History
#    -------------------------------------------------------------------------------
#    Author                     Date            Version No   Description
#    -------------------------------------------------------------------------------
#
#*************************************************************************************************

Ask ()
{        print -n $1
         read NEW_VAR
         while [[ -z ${NEW_VAR} ]]
         do
           print -n $1
           read NEW_VAR
                if [[ -z ${NEW_VAR} ]]
                then
                        print "Blank $2 settings are not allowed, re-enter."
                else
                        $2=${NEW_VAR}
                        export $2
                fi
        done
        export $2=${NEW_VAR}
        return 1
}

check_sql_connection ()
{
        v_username=$1
        v_password=$2
        v_database=$3

        sqlplus -l -s $v_username/$v_password@$v_database @"exit.sql"

        if [ $? -ne 0 ]
        then 
                echo "Sql Connection Error $v_username/$v_password@$v_database \n\n\n"
                exit 2 
        else
                echo "Success"
        fi
}

display_deployment_successful()
{    
    echo "\n\nDeployment Successful from STAGE $v_interim_stage to STAGE $v_stageTo"
    echo "=========================================================================\n\n"
}

check_string()
{
if [ -z $1 ]
then
    print "INVALID SETTINGS"
    exit
fi
}


check_log_file ()
{

        if [ -f $1 ]
        then
                echo "Checking log file $1"
        else
                echo "Log file $1 does not exist\n\n\n"
                echo "failure at v_stageFrom=" $v_stageFrom
                exit 1
        fi

        chkLogStatus_err=`grep -ic 'Errors' $1` 
        chkLogStatus_ora=`grep -ic 'ORA-' $1`
        chkLogStatus_war=`grep -ic 'Warning:$' $1`
        chkLogStatus_noerr=`grep -ic '^No Errors.$' $1`
        chkLogStatus_nosp=`grep -ic 'SP2-' $1`
#        echo 'ERR' $chkLogStatus_err
#        echo 'ORA-' $chkLogStatus_ora
#        echo 'Warning' $chkLogStatus_war
#        echo 'No ERROR' $chkLogStatus_noerr
#        echo 'SP2' $chkLogStatus_nosp
        error_cnt=`expr $chkLogStatus_err + $chkLogStatus_ora + $chkLogStatus_war + $chkLogStatus_nosp - $chkLogStatus_noerr`

        if [ $error_cnt -gt 0 ]
        then
                echo "ERRORS IN LOG FILE $1 \n\n\n"
                echo "FAILURE AT STAGE=" $v_stageFrom

                exit
        else
                echo "NO ERRORS in log file $1\n\n\n "
                return 0;
        fi
}


check_log_file_2 ()
{

        if [ -f $1 ]
        then
                echo "Checking log file $1"
        else
                echo "Log file $1 does not exist\n\n\n"
                echo "failure at v_stageFrom=" $v_stageFrom
                exit 1
        fi

        chkLogStatus_err=`grep -c 'Errors' $1` 
        chkLogStatus_ora=`grep -ic 'ORA-' $1`
        chkLogStatus_war=`grep -ic 'Warning:$' $1`
        chkLogStatus_noerr=`grep -ic '^No Errors.$' $1`
        chkLogStatus_nosp=`grep -ic 'SP2-' $1`
#        echo 'ERR' $chkLogStatus_err
#        echo 'ORA-' $chkLogStatus_ora
#        echo 'Warning' $chkLogStatus_war
#        echo 'No ERROR' $chkLogStatus_noerr
#        echo 'SP2' $chkLogStatus_nosp
        error_cnt=`expr $chkLogStatus_err + $chkLogStatus_ora + $chkLogStatus_war + $chkLogStatus_nosp - $chkLogStatus_noerr`

        if [ $error_cnt -gt 0 ]
        then
                echo "ERRORS IN LOG FILE $1 \n\n\n"
                echo "FAILURE AT STAGE=" $v_stageFrom

                exit
        else
                echo "NO ERRORS in log file $1\n\n\n "
                return 0;
        fi
}

clear
echo "\n\nAccepting parameter values"
echo "==========================\n"

Ask "Enter Starting Stage      : " v_stageFrom
Ask "Enter End Stage           : " v_stageTo

v_interim_stage="$v_stageFrom"

echo "\n\nChecking parameters"
echo "===================\n"

env=`grep 'ENVIRONMENT_NAME' setup.ini |cut -f2 -d=|tr '[a-z]' '[A-Z]'`
echo "Checking Parameter for ENVIRONMENT_NAME"
check_string $env

connstr=`grep -w 'DATABASE_CONNECTION_STRING' setup.ini |cut -f2 -d=`
echo "Checking Parameter for DATABASE_CONNECTION_STRING"
check_string $connstr


housekeeping_schema=`grep -w 'HOUSEKEEPING_SCHEMA_NAME' setup.ini |cut -f2 -d=`
housekeeping_passwd=`grep -w 'HOUSEKEEPING_SCHEMA_PASSWORD' setup.ini |cut -f2 -d=`
echo "Checking Parameter for HOUSEKEEPING SCHEMA"
check_string $housekeeping_schema
check_string $housekeeping_passwd
check_sql_connection $housekeeping_schema $housekeeping_passwd $connstr


prelanding_schema=`grep -w 'PRELANDING_SCHEMA_NAME' setup.ini |cut -f2 -d=`
prelanding_passwd=`grep -w 'PRELANDING_SCHEMA_PASSWORD' setup.ini |cut -f2 -d=`
echo "Checking Parameter for PRELANDING_SCHEMA"
check_string $prelanding_schema
check_string $prelanding_passwd
check_sql_connection $prelanding_schema $prelanding_passwd $connstr

process_manager_schema=`grep -w 'PROCESS_MANAGER_SCHEMA_NAME' setup.ini |cut -f2 -d=`
process_manager_passwd=`grep -w 'PROCESS_MANAGER_SCHEMA_PASSWORD' setup.ini |cut -f2 -d=`
echo "Checking Parameter for PROCESS_MANAGER_SCHEMA"
check_string $process_manager_schema
check_string $process_manager_passwd
check_sql_connection $process_manager_schema $process_manager_passwd $connstr

ref_schema=`grep -w 'REFERENCE_SCHEMA_NAME' setup.ini |cut -f2 -d=`
ref_passwd=`grep -w 'REFERENCE_SCHEMA_PASSWORD' setup.ini |cut -f2 -d=`
echo "Checking Parameter for REFERENCE_SCHEMA"
check_string $ref_schema
check_string $ref_passwd
check_sql_connection $ref_schema $ref_passwd $connstr

stg_schema=`grep -w 'SUS_STAGING_SCHEMA_NAME' setup.ini |cut -f2 -d=`
stg_passwd=`grep -w 'SUS_STAGING_SCHEMA_PASSWORD' setup.ini |cut -f2 -d=`
echo "Checking Parameter for SUS_STAGING_SCHEMA"
check_string $stg_schema
check_string $stg_passwd
check_sql_connection $stg_schema $stg_passwd $connstr

lnd_schema=`grep -w 'SUS_LANDING_SCHEMA_NAME' setup.ini |cut -f2 -d=`
lnd_passwd=`grep -w 'SUS_LANDING_SCHEMA_PASSWORD' setup.ini |cut -f2 -d=`
echo "Checking Parameter for SUS_STAGING_SCHEMA"
check_string $lnd_schema
check_string $lnd_passwd
check_sql_connection $lnd_schema $lnd_passwd $connstr

tracking_schema=`grep -w 'TRACKING_SCHEMA_NAME' setup.ini |cut -f2 -d=`
tracking_passwd=`grep -w 'TRACKING_SCHEMA_PASSWORD' setup.ini |cut -f2 -d=`
echo "Checking Parameter for TRACKING_SCHEMA"
check_string $tracking_schema
check_string $tracking_passwd
check_sql_connection $tracking_schema $tracking_passwd $connstr

audit_schema=`grep -w 'AUDIT_SCHEMA_NAME' setup.ini |cut -f2 -d=`
audit_passwd=`grep -w 'AUDIT_SCHEMA_PASSWORD' setup.ini |cut -f2 -d=`
echo "Checking Parameter for AUDIT_SCHEMA"
check_string $audit_schema
check_string $audit_passwd
check_sql_connection $audit_schema $audit_passwd $connstr


icowner1_schema=`grep -w 'ICOWNER1_SCHEMA_NAME' setup.ini |cut -f2 -d=`
icowner1_passwd=`grep -w 'ICOWNER1_SCHEMA_PASSWORD' setup.ini |cut -f2 -d=`
echo "Checking Parameter for ICOWNER1_SCHEMA"
check_string $icowner1_schema
check_string $icowner1_passwd
check_sql_connection $icowner1_schema $icowner1_passwd $connstr

cab_sus_schema=`grep -w 'CAB_SUS_SCHEMA_NAME' setup.ini |cut -f2 -d=`
cab_sus_passwd=`grep -w 'CAB_SUS_SCHEMA_PASSWORD' setup.ini |cut -f2 -d=`
echo "Checking Parameter for CAB_SUS_SCHEMA"
check_string $cab_sus_schema
check_string $cab_sus_passwd
check_sql_connection $cab_sus_schema $cab_sus_passwd $connstr

rbac_schema=`grep -w 'RBAC_SCHEMA_NAME' setup.ini |cut -f2 -d=`
rbac_passwd=`grep -w 'RBAC_SCHEMA_PASSWORD' setup.ini |cut -f2 -d=`
echo "Checking Parameter for RBAC_SCHEMA"
check_string $rbac_schema
check_string $rbac_passwd
check_sql_connection $rbac_schema $rbac_passwd $connstr

job_control_schema=`grep -w 'JOB_CONTROL_SCHEMA_NAME' setup.ini |cut -f2 -d=`
job_control_passwd=`grep -w 'JOB_CONTROL_SCHEMA_PASSWORD' setup.ini |cut -f2 -d=`
echo "Checking Parameter for JOB_CONTROL_SCHEMA"
check_string $job_control_schema
check_string $job_control_passwd
check_sql_connection $job_control_schema $job_control_passwd $connstr

stg_archive_schema=`grep -w 'STAGING_ARCHIVE_SCHEMA_NAME' setup.ini |cut -f2 -d=`
stg_archive_passwd=`grep -w 'STAGING_ARCHIVE_SCHEMA_PASSWORD' setup.ini |cut -f2 -d=`
echo "Checking Parameter for STAGING_ARCHIVE_SCHEMA"
check_string $stg_archive_schema
check_string $stg_archive_passwd
check_sql_connection $stg_archive_schema $stg_archive_passwd $connstr

hes_schema=`grep -w 'HES_SCHEMA_NAME' setup.ini |cut -f2 -d=`
hes_passwd=`grep -w 'HES_SCHEMA_PASSWORD' setup.ini |cut -f2 -d=`
echo "Checking Parameter for HES_SCHEMA"
check_string $hes_schema
check_string $hes_passwd
check_sql_connection $hes_schema $hes_passwd $connstr

ext_lnd_schema=`grep -w 'EXTRACT_LANDING_SCHEMA_NAME' setup.ini |cut -f2 -d=`
ext_lnd_passwd=`grep -w 'EXTRACT_LANDING_SCHEMA_PASSWORD' setup.ini |cut -f2 -d=`
echo "Checking Parameter for EXTRACT_LANDING_SCHEMA"
check_string $ext_lnd_schema
check_string $ext_lnd_passwd
check_sql_connection $ext_lnd_schema $ext_lnd_passwd $connstr

ext_mart_schema=`grep -w 'EXTRACT_MART_SCHEMA_NAME' setup.ini |cut -f2 -d=`
ext_mart_passwd=`grep -w 'EXTRACT_MART_SCHEMA_PASSWORD' setup.ini |cut -f2 -d=`
echo "Checking Parameter for EXTRACT_MART_SCHEMA"
check_string $ext_mart_schema
check_string $ext_mart_passwd
check_sql_connection $ext_mart_schema $ext_mart_passwd $connstr

sar_schema=`grep -w 'SAR_SCHEMA_NAME' setup.ini |cut -f2 -d=`
sar_passwd=`grep -w 'SAR_SCHEMA_PASSWORD' setup.ini |cut -f2 -d=`
echo "Checking Parameter for SAR_SCHEMA"
check_string $sar_schema
check_string $sar_passwd
check_sql_connection $sar_schema $sar_passwd $connstr

sus_portal_schema=`grep -w 'SUS_PORTAL_SCHEMA_NAME' setup.ini |cut -f2 -d=`
sus_portal_passwd=`grep -w 'SUS_PORTAL_SCHEMA_PASSWORD' setup.ini |cut -f2 -d=`
echo "Checking Parameter for SUS_PORTAL_SCHEMA"
check_string $sus_portal_schema
check_string $sus_portal_passwd
check_sql_connection $sus_portal_schema $sus_portal_passwd $connstr

bo_adhoc_schema=`grep -w 'BO_ADHOC_SCHEMA_NAME' setup.ini |cut -f2 -d=`
bo_adhoc_passwd=`grep -w 'BO_ADHOC_SCHEMA_PASSWORD' setup.ini |cut -f2 -d=`
echo "Checking Parameter for BO_ADHOC SCHEMA"
check_string $bo_adhoc_schema
check_string $bo_adhoc_passwd
check_sql_connection $bo_adhoc_schema $bo_adhoc_passwd $connstr

echo " "
echo " "
echo "\n\n\nStarting Deployment\n\n\n" 

if [ $v_stageFrom -le 0 ]
then
        echo '=============================================================================='
        echo 'STARTING STAGE = '$v_stageFrom
        echo "../AuditTracking/ddl/audit/setup_audit_schema.sql"
        sqlplus  -s $audit_schema/$audit_passwd@$connstr          @"../AuditTracking/ddl/audit/setup_audit_schema.sql" $env 
        check_log_file "setup_audit_schema.log"
        echo 'COMPLETED STAGE = '$v_stageFrom 
        echo '=============================================================================='

        if  [ $v_stageFrom == $v_stageTo ]
        then
            display_deployment_successful
            exit
        fi

fi

if [ $v_stageFrom -le 10 ]
then
        v_stageFrom="10"
        echo '=============================================================================='
        echo 'STARTING STAGE = '$v_stageFrom
        echo "../AuditTracking/ddl/tracking/setup_sus_tracking_schema.sql"
        sqlplus  -s $tracking_schema/$tracking_passwd@$connstr          @"../AuditTracking/ddl/tracking/setup_sus_tracking_schema.sql" $env
        check_log_file "setup_sus_tracking_schema.log"
        echo 'COMPLETED STAGE = '$v_stageFrom 
        echo '=============================================================================='

        if  [ $v_stageFrom == $v_stageTo ]
        then
              display_deployment_successful
              exit
        fi

fi


if [ $v_stageFrom -le 20 ]
then
        v_stageFrom="20" 
        echo '=============================================================================='
        echo 'STARTING STAGE = '$v_stageFrom
        echo "../AuditTracking/packages/tracking/setup_sus_tracking_pkg.sql"
        sqlplus  -s $tracking_schema/$tracking_passwd@$connstr          @"../AuditTracking/packages/tracking/setup_sus_tracking_pkg.sql" $env 
        check_log_file "setup_sus_tracking_pkg.log"
        echo 'COMPLETED STAGE = '$v_stageFrom 
        echo '=============================================================================='

        if  [ $v_stageFrom == $v_stageTo ]
        then
            display_deployment_successful
            exit
        fi

fi


if [ $v_stageFrom -le 30 ]
then
         v_stageFrom="30" 
        echo '=============================================================================='
        echo 'STARTING STAGE = '$v_stageFrom
        echo "../CAB/ddl/cab_warehouse/setup_cab_schema.sql"
        sqlplus  -s $cab_sus_schema/$cab_sus_passwd@$connstr          @"../CAB/ddl/cab_warehouse/setup_cab_schema.sql" $env
        check_log_file "setup_cab_schema.log"
        echo 'COMPLETED STAGE = '$v_stageFrom
        echo '=============================================================================='

        if  [ $v_stageFrom == $v_stageTo ]
        then
            display_deployment_successful
            exit
        fi

fi

if [ $v_stageFrom -le 40 ]
then
         v_stageFrom="40" 
        echo '=============================================================================='
        echo 'STARTING STAGE = '$v_stageFrom
        echo "../Reference/ddl/reference/setup_reference_schema.sql"
        sqlplus  -s $ref_schema/$ref_passwd@$connstr          @"../Reference/ddl/reference/setup_reference_schema.sql" $env
        check_log_file "setup_reference_schema.log"
        echo 'COMPLETED STAGE = '$v_stageFrom
        echo '=============================================================================='

        if  [ $v_stageFrom == $v_stageTo ]
        then
            display_deployment_successful
            exit
        fi

fi


if [ $v_stageFrom -le 50 ]
then
        v_stageFrom="50"
        echo '=============================================================================='
        echo 'STARTING STAGE = '$v_stageFrom
        echo "../Reference/packages/reference/setup_reference_pkg.sql"
        sqlplus  -s $ref_schema/$ref_passwd@$connstr          @"../Reference/packages/reference/setup_reference_pkg.sql" $env
        check_log_file "setup_reference_pkg.log"
        echo 'COMPLETED STAGE = '$v_stageFrom 
        echo '=============================================================================='

        if  [ $v_stageFrom == $v_stageTo ]
        then 
              display_deployment_successful
              exit
        fi

fi

if [ $v_stageFrom -le 60 ]
then
        v_stageFrom="60"
        echo '=============================================================================='
        echo 'STARTING STAGE = '$v_stageFrom
        echo "../PreLanding/ddl/prelanding/setup_prelanding_schema.sql"
        sqlplus  -s $prelanding_schema/$prelanding_passwd@$connstr          @"../PreLanding/ddl/prelanding/setup_prelanding_schema.sql" $env
        check_log_file "setup_prelanding_schema.log"
        echo 'COMPLETED STAGE = '$v_stageFrom 
        echo '=============================================================================='

        if  [ $v_stageFrom == $v_stageTo ]
        then
              display_deployment_successful
              exit
        fi

fi

if [ $v_stageFrom -le 70 ]
then
        v_stageFrom="70"
        echo '=============================================================================='
        echo 'STARTING STAGE = '$v_stageFrom
        echo "../PreLanding/general/grant_prelanding_reference_rdm.sql"
        sqlplus  -s $ref_schema/$ref_passwd@$connstr          @"../PreLanding/general/grant_prelanding_reference_rdm.sql" $env
        check_log_file "grant_prelanding_reference_rdm.log"
        echo 'COMPLETED STAGE = '$v_stageFrom 
        echo '=============================================================================='

        if  [ $v_stageFrom == $v_stageTo ]
        then
              display_deployment_successful
              exit
        fi

fi

if [ $v_stageFrom -le 80 ]
then
        v_stageFrom="80"
        echo '=============================================================================='
        echo 'STARTING STAGE = '$v_stageFrom
        echo "../PreLanding/packages/prelanding/setup_prelanding_pkg.sql"
        sqlplus  -s $prelanding_schema/$prelanding_passwd@$connstr          @"../PreLanding/packages/prelanding/setup_prelanding_pkg.sql" $env
        check_log_file "setup_prelanding_pkg.log"
        echo 'COMPLETED STAGE = '$v_stageFrom
        echo '=============================================================================='

        if  [ $v_stageFrom == $v_stageTo ]
        then
              display_deployment_successful
              exit
        fi

fi


if [ $v_stageFrom -le 90 ]
then
        v_stageFrom="90"
        echo '=============================================================================='
        echo 'STARTING STAGE = '$v_stageFrom
        echo "../ProcessControl/ddl/processcontrol/setup_icowner1_schema.sql"
        sqlplus  -s $icowner1_schema/$icowner1_passwd@$connstr          @"../ProcessControl/ddl/processcontrol/setup_icowner1_schema.sql" $env 
        check_log_file "setup_icowner1_schema.log"
        echo 'COMPLETED STAGE = '$v_stageFrom 
        echo '=============================================================================='

        if  [ $v_stageFrom == $v_stageTo ]
        then
            display_deployment_successful
            exit
        fi

fi


if [ $v_stageFrom -le 100 ]
then
        v_stageFrom="100"
        echo '=============================================================================='
        echo 'STARTING STAGE = '$v_stageFrom
        echo "../ProcessControl/packages/processcontrol/setup_icowner1_pkg.sql"
        sqlplus  -s $icowner1_schema/$icowner1_passwd@$connstr          @"../ProcessControl/packages/processcontrol/setup_icowner1_pkg.sql" $env 
        check_log_file "setup_icowner1_pkg.log"
        echo 'COMPLETED STAGE = '$v_stageFrom 
        echo '=============================================================================='

        if  [ $v_stageFrom == $v_stageTo ]
        then
            display_deployment_successful
            exit
        fi

fi

if [ $v_stageFrom -le 110 ]
then
        v_stageFrom="110"
        echo '=============================================================================='
        echo 'STARTING STAGE = '$v_stageFrom
        echo "../RBAC/DDL/setup_rbac_schema.sql"
        sqlplus  -s $rbac_schema/$rbac_passwd@$connstr          @"../RBAC/DDL/setup_rbac_schema.sql" $env 
        check_log_file "setup_rbac_schema.log"
        echo 'COMPLETED STAGE = '$v_stageFrom 
        echo '=============================================================================='

        if  [ $v_stageFrom == $v_stageTo ]
        then
            display_deployment_successful
            exit
        fi

fi


if [ $v_stageFrom -le 120 ]
then
        v_stageFrom="120"
        echo '=============================================================================='
        echo 'STARTING STAGE = '$v_stageFrom
        echo "../ProcessManager/ddl/processmanager/setup_sus_process_mgr_schema.sql"
        sqlplus  -s $process_manager_schema/$process_manager_passwd@$connstr          @"../ProcessManager/ddl/processmanager/setup_sus_process_mgr_schema.sql" $env 
        check_log_file "setup_sus_process_mgr_schema.log"
        echo 'COMPLETED STAGE = '$v_stageFrom 
        echo '=============================================================================='

        if  [ $v_stageFrom == $v_stageTo ]
        then
            display_deployment_successful
            exit
        fi

fi

if [ $v_stageFrom -le 130 ]
then
        v_stageFrom="130"
        echo '=============================================================================='
        echo 'STARTING STAGE = '$v_stageFrom
        echo "../BO_ADHOC/DDL/BO_ADHOC/setup_bo_adhoc_schema.sql"
        sqlplus  -s $bo_adhoc_schema/$bo_adhoc_passwd@$connstr          @"../BO_ADHOC/DDL/BO_ADHOC/setup_bo_adhoc_schema.sql" $env
        check_log_file "setup_bo_adhoc_schema.log"
        echo 'COMPLETED STAGE = '$v_stageFrom
        echo '=============================================================================='

        if  [ $v_stageFrom == $v_stageTo ]
        then
              display_deployment_successful
              exit
        fi

fi

if [ $v_stageFrom -le 140 ]
then
        v_stageFrom="140"
        echo '=============================================================================='
        echo 'STARTING STAGE = '$v_stageFrom
        echo "../JobControl/ddl/job_control/setup_job_control_schema.sql"
        sqlplus  -s $job_control_schema/$job_control_passwd@$connstr          @"../JobControl/ddl/job_control/setup_job_control_schema.sql" $env 
        check_log_file "setup_job_control_schema.log"
        echo 'COMPLETED STAGE = '$v_stageFrom 
        echo '=============================================================================='

        if  [ $v_stageFrom == $v_stageTo ]
        then
            display_deployment_successful
            exit
        fi

fi

if [ $v_stageFrom -le 150 ]
then
        v_stageFrom="150"
        echo '=============================================================================='
        echo 'STARTING STAGE = '$v_stageFrom
        echo "../JobControl/packages/job_control/setup_job_control_pkg.sql"
        sqlplus  -s $job_control_schema/$job_control_passwd@$connstr          @"../JobControl/packages/job_control/setup_job_control_pkg.sql" $env 
        check_log_file "setup_job_control_pkg.log"
        echo 'COMPLETED STAGE = '$v_stageFrom 
        echo '=============================================================================='

        if  [ $v_stageFrom == $v_stageTo ]
        then
            display_deployment_successful
            exit
        fi

fi

if [ $v_stageFrom -le 160 ]
then
        v_stageFrom="160"
        echo '=============================================================================='
        echo 'STARTING STAGE = '$v_stageFrom
        echo "../Housekeeping/ddl/housekeeping/setup_housekeep_schema.sql"
        sqlplus  -s $housekeeping_schema/$housekeeping_passwd@$connstr          @"../Housekeeping/ddl/housekeeping/setup_housekeep_schema.sql" $env 
        check_log_file "setup_housekeep_schema.log"
        echo 'COMPLETED STAGE = '$v_stageFrom 
        echo '=============================================================================='

        if  [ $v_stageFrom == $v_stageTo ]
        then
            display_deployment_successful
            exit
        fi

fi

if [ $v_stageFrom -le 170 ]
then
        v_stageFrom="170"
        echo '=============================================================================='
        echo 'STARTING STAGE = '$v_stageFrom
        echo "../Housekeeping/Packages/housekeeping/setup_housekeeping_pkg_schema.sql"
        sqlplus  -s $housekeeping_schema/$housekeeping_passwd@$connstr          @"../Housekeeping/Packages/housekeeping/setup_housekeeping_pkg_schema.sql" $env 
        check_log_file "setup_housekeeping_pkg_schema.log"
        echo 'COMPLETED STAGE = '$v_stageFrom 
        echo '=============================================================================='

        if  [ $v_stageFrom == $v_stageTo ]
        then
            display_deployment_successful
            exit
        fi

fi

if [ $v_stageFrom -le 180 ]
then
        v_stageFrom="180"
        echo '=============================================================================='
        echo 'STARTING STAGE = '$v_stageFrom
        echo "../CDS-V6/ddl/landing/setup_cds_landing_schema.sql"
        sqlplus  -s $lnd_schema/$lnd_passwd@$connstr          @"../CDS-V6/ddl/landing/setup_cds_landing_schema.sql" $env 
        check_log_file "setup_cds_landing_schema.log"
        echo 'COMPLETED STAGE = '$v_stageFrom 
        echo '=============================================================================='

        if  [ $v_stageFrom == $v_stageTo ]
        then
            display_deployment_successful
            exit
        fi

fi

if [ $v_stageFrom -le 190 ]
then
        v_stageFrom="190"
        echo '=============================================================================='
        echo 'STARTING STAGE = '$v_stageFrom
        echo "../CDS-V6/ddl/staging/setup_cds_staging_schema.sql"
        sqlplus  -s $stg_schema/$stg_passwd@$connstr          @"../CDS-V6/ddl/staging/setup_cds_staging_schema.sql" $env 
        check_log_file "setup_cds_staging_schema.log"
        echo 'COMPLETED STAGE = '$v_stageFrom 
        echo '=============================================================================='

        if  [ $v_stageFrom == $v_stageTo ]
        then
            display_deployment_successful
            exit
        fi

fi

if [ $v_stageFrom -le 200 ]
then
        v_stageFrom="200"
        echo '=============================================================================='
        echo 'STARTING STAGE = '$v_stageFrom
        echo "../CDS-V6/ddl/staging_archive/setup_staging_archive_schema.sql"
        sqlplus  -s $stg_archive_schema/$stg_archive_passwd@$connstr          @"../CDS-V6/ddl/staging_archive/setup_staging_archive_schema.sql" $env 
        check_log_file "setup_staging_archive_schema.log"
        echo 'COMPLETED STAGE = '$v_stageFrom 
        echo '=============================================================================='

        if  [ $v_stageFrom == $v_stageTo ]
        then
            display_deployment_successful
            exit
        fi

fi


if [ $v_stageFrom -le 210 ]
then
        v_stageFrom="210"
        echo '=============================================================================='
        echo 'STARTING STAGE = '$v_stageFrom
        echo "../CDS-V6/packages/landing/setup_cds_landing_schema_pkg.sql"
        sqlplus  -s $lnd_schema/$lnd_passwd@$connstr          @"../CDS-V6/packages/landing/setup_cds_landing_schema_pkg.sql" $env 
        check_log_file "setup_cds_landing_schema_pkg.log"
        echo 'COMPLETED STAGE = '$v_stageFrom 
        echo '=============================================================================='

        if  [ $v_stageFrom == $v_stageTo ]
        then
            display_deployment_successful
            exit
        fi

fi


if [ $v_stageFrom -le 220 ]
then
        v_stageFrom="220"
        echo '=============================================================================='
        echo 'STARTING STAGE = '$v_stageFrom
        echo "../CDS-V6/packages/staging/setup_cds_staging_schema_pkg.sql"
        sqlplus  -s $stg_schema/$stg_passwd@$connstr          @"../CDS-V6/packages/staging/setup_cds_staging_schema_pkg.sql" $env 
        check_log_file "setup_cds_staging_schema_pkg.log"
        echo 'COMPLETED STAGE = '$v_stageFrom 
        echo '=============================================================================='

        if  [ $v_stageFrom == $v_stageTo ]
        then
            display_deployment_successful
            exit
        fi

fi

if [ $v_stageFrom -le 230 ]
then
        v_stageFrom="230"
        echo '=============================================================================='
        echo 'STARTING STAGE = '$v_stageFrom
        echo "../ExtractMart/ddl/extract_landing/setup_extract_landing_schema.sql"
        sqlplus  -s $ext_lnd_schema/$ext_lnd_passwd@$connstr          @"../ExtractMart/ddl/extract_landing/setup_extract_landing_schema.sql" $env 
        check_log_file "setup_extract_landing_schema.log"
        echo 'COMPLETED STAGE = '$v_stageFrom 
        echo '=============================================================================='

        if  [ $v_stageFrom == $v_stageTo ]
        then
            display_deployment_successful
            exit
        fi

fi

if [ $v_stageFrom -le 240 ]
then
        v_stageFrom="240"
        echo '=============================================================================='
        echo 'STARTING STAGE = '$v_stageFrom
        echo "../ExtractMart/ddl/extract_mart/setup_sus_ext_mart_schema.sql"
        sqlplus  -s $ext_mart_schema/$ext_mart_passwd@$connstr          @"../ExtractMart/ddl/extract_mart/setup_sus_ext_mart_schema.sql" $env 
        check_log_file "setup_sus_ext_mart_schema.log"
        echo 'COMPLETED STAGE = '$v_stageFrom 
        echo '=============================================================================='

        if  [ $v_stageFrom == $v_stageTo ]
        then
            display_deployment_successful
            exit
        fi

fi

if [ $v_stageFrom -le 250 ]
then
        v_stageFrom="250"
        echo '=============================================================================='
        echo 'STARTING STAGE = '$v_stageFrom
        echo "../ExtractMart/packages/extract_landing/setup_sus_ext_lnd_pkg.sql"
        sqlplus  -s $ext_lnd_schema/$ext_lnd_passwd@$connstr          @"../ExtractMart/packages/extract_landing/setup_sus_ext_lnd_pkg.sql" $env 
        check_log_file "setup_sus_ext_lnd_pkg.log"
        echo 'COMPLETED STAGE = '$v_stageFrom 
        echo '=============================================================================='

        if  [ $v_stageFrom == $v_stageTo ]
        then
            display_deployment_successful
            exit
        fi

fi

if [ $v_stageFrom -le 260 ]
then
        v_stageFrom="260"
        echo '=============================================================================='
        echo 'STARTING STAGE = '$v_stageFrom
        echo "../HESExtract/ddl/hes/setup_sus_hes_schema.sql"
        sqlplus  -s $hes_schema/$hes_passwd@$connstr          @"../HESExtract/ddl/hes/setup_sus_hes_schema.sql" $env 
        check_log_file "setup_sus_hes_schema.log"
        echo 'COMPLETED STAGE = '$v_stageFrom 
        echo '=============================================================================='

        if  [ $v_stageFrom == $v_stageTo ]
        then
            display_deployment_successful
            exit
        fi

fi

if [ $v_stageFrom -le 270 ]
then
        v_stageFrom="270"
        echo '=============================================================================='
        echo 'STARTING STAGE = '$v_stageFrom
        echo "../HESExtract/packages/hes/setup_hes_pkg.sql"
        sqlplus  -s $hes_schema/$hes_passwd@$connstr          @"../HESExtract/packages/hes/setup_hes_pkg.sql" $env 
        check_log_file "setup_hes_pkg.log"
        echo 'COMPLETED STAGE = '$v_stageFrom 
        echo '=============================================================================='

        if  [ $v_stageFrom == $v_stageTo ]
        then
            display_deployment_successful
            exit
        fi

fi

if [ $v_stageFrom -le 280 ]
then
        v_stageFrom="280"
        echo '=============================================================================='
        echo 'STARTING STAGE = '$v_stageFrom
        echo "../SAR/ddl/sar/setup_sar_schema.sql"
        sqlplus  -s $sar_schema/$sar_passwd@$connstr          @"../SAR/ddl/sar/setup_sar_schema.sql" $env 
        check_log_file "setup_sar_schema.log"
        echo 'COMPLETED STAGE = '$v_stageFrom 
        echo '=============================================================================='

        if  [ $v_stageFrom == $v_stageTo ]
        then
            display_deployment_successful
            exit
        fi

fi

if [ $v_stageFrom -le 290 ]
then
        v_stageFrom="290"
        echo '=============================================================================='
        echo 'STARTING STAGE = '$v_stageFrom
        echo "../SAR/packages/sar/setup_sar_pkg_schema.sql"
        sqlplus  -s $sar_schema/$sar_passwd@$connstr          @"../SAR/packages/sar/setup_sar_pkg_schema.sql" $env 
        check_log_file "setup_sar_pkg_schema.log"
        echo 'COMPLETED STAGE = '$v_stageFrom 
        echo '=============================================================================='

        if  [ $v_stageFrom == $v_stageTo ]
        then
            display_deployment_successful
            exit
        fi

fi

if [ $v_stageFrom -le 300 ]
then
        v_stageFrom="300"
        echo '=============================================================================='
        echo 'STARTING STAGE = '$v_stageFrom
        echo "../Sus_Portal/ddl/sus_portal/setup_sus_portal_schema.sql"
        sqlplus  -s $sus_portal_schema/$sus_portal_passwd@$connstr          @"../Sus_Portal/ddl/sus_portal/setup_sus_portal_schema.sql" $env 
        check_log_file "setup_sus_portal_schema.log"
        echo 'COMPLETED STAGE = '$v_stageFrom 
        echo '=============================================================================='

        if  [ $v_stageFrom == $v_stageTo ]
        then
            display_deployment_successful
            exit
        fi

fi



echo "\n\nDeployment Complete"
echo "===================\n\n"
