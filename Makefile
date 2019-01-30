.PHONY: access-h1 access-h2 bench-h1 bench-h2

HOST = kuryu.local

ah1:
	curl -v -k https://${HOST}:4443/app/

ah2:
	curl -v -k https://${HOST}:4444/app/

bh1:
	h2load -n 10000 -c 100 -m 1 https://${HOST}:4443/app/

bh2:
	h2load -n 10000 -c 100 -m 1 https://${HOST}:4444/app/

uwsgitop:
	uwsgitop 127.0.0.1:9191
