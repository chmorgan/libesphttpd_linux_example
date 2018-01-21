# test that the server can handle very long url strings without
# crashes or memory issues

valgrind --leak-check=full ./httpd&
httpd_pid=$!
sleep 1

for URL_LEN in 64 128 256 512 1024
do
	long_url=$(head -c ${URL_LEN} < /dev/zero | tr '\0' '\141')
	echo "URL_LEN ${URL_LEN}"
	echo "long_url " ${long_url}

	timeout 5s curl -k -X GET http://localhost:9000/${long_url}
done

# is valgrind still running? if so the test passed, the server didn't
# crash
if  ps -p ${httpd_pid} > /dev/null
then
	exit_code=0
else
	exit_code=1
fi

# shut down httpd
kill -KILL ${httpd_pid} > /dev/null 2>&1

exit ${exit_code}
