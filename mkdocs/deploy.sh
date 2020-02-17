source ./mkdocs.yml.sh 
docker build -t $Pjname -f ./dockerfile.mkdocs . && Successflag=$?
[ "$Successflag" ] && docker stop $Pjname && docker rm `docker stop $Pjname` 
[ "$Successflag" ] && docker run --name $Pjname -p $Port:80 -d $Pjname && \
docker ps |grep $Pjname
