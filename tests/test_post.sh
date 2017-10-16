# test that we can perform a post of data to a cgi handler

./httpd&
httpd_pid=$!

# generate some random data to upload
# NOTE: This test was previously failing at a size of 300000 but would work at 100000,
# so we are using 300000 here
dd bs=1 count=300000 if=/dev/urandom of=testfile.bin

timeout 5s curl -k -X POST https://localhost:9000/upload --data-binary @testfile.bin
if [ $? -ne 0 ]
then
    exit_code=1
fi

# shut down httpd
kill -KILL ${httpd_pid}

exit ${exit_code}
