INSTALL_DEP="False"
PLAYBOOK="deployment"
INSTANCE_NAME="vm-mydivision-deploytest-model"
AWS_S3_BUCKET="s3://s3-mydivision-deploytest-model"
AWS_CLOUDWATCH="/aws/ssm/runcommand/logs"


INSTANCE_ID=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=${INSTANCE_NAME}" "Name=instance-state-name,Values=pending,running,stopping,stopped" --query "Reservations[*].Instances[*].InstanceId" --output text)
echo $INSTANCE_ID

result=`aws ssm send-command \
            --document-name "AWS-ApplyAnsiblePlaybooks" \
            --document-version "1" \
            --targets '[{"Key":"InstanceIds","Values":["'${INSTANCE_ID}'"]}]' \
            --parameters '{"SourceType":["S3"],"SourceInfo":["{\"path\": \"https://'${AWS_S3_BUCKET}'.s3.'${AWS_DEFAULT_REGION}'.amazonaws.com/'${PLAYBOOK}'.yml\"}"],"InstallDependencies":["'${INSTALL_DEP}'"],"PlaybookFile":["'${PLAYBOOK}'.yml"],"Check":["False"],"Verbose":["-v"],"TimeoutSeconds":["3600"]}' \
            --timeout-seconds 600 \
            --max-concurrency "50" \
            --max-errors "0" \
            --cloud-watch-output-config '{"CloudWatchOutputEnabled":true,"CloudWatchLogGroupName":"'${AWS_CLOUDWATCH}'"}'`
id=$(echo $result | jq -r .Command.CommandId)
echo $id

# poll status, 15mins (90 * 10sec) timeout
# refer to status types here: https://docs.aws.amazon.com/systems-manager/latest/userguide/monitor-commands.html
# ------------------------------
count=90
for i in $(seq $count); do
    checkstatus=`aws ssm get-command-invocation --command-id $id --instance-id $INSTANCE_ID`;
    getstatus=$(echo $checkstatus | jq -r .StatusDetails);

    if [[ $getstatus == "Pending" ]]; then
        echo "[INFO] pending... please wait"
        sleep 10
    elif [[ $getstatus == "InProgress" ]]; then
        echo "[INFO] in progress... please wait"
        sleep 10
    elif [[ $getstatus == "Success" ]]; then
        echo "[INFO] Success! Images deployed to EC2"
        break
    elif [[ $getstatus == "Failed" ]]; then
        # retrieve logs from cloudwatch if deployment fails
        # ------------------------------
        getloggroup=$(echo $checkstatus | jq -r .CloudWatchOutputConfig.CloudWatchLogGroupName)
        aws logs get-log-events \
            --log-group-name $getloggroup \
            --log-stream-name "$id/$INSTANCE_ID/runShellScript/stdout" \
            --query events[*].message \
            --output text
        echo "[ERROR] deployment failed, please check SSM logs above"
        exit 1
    fi;
done;


echo "[INFO] Final Status:" $getstatus
if [[ $getstatus == "InProgress" ]]; then
    echo "[ERROR] Timeout, consider increase checktime"
    exit 1;
fi;