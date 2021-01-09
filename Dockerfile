FROM python:latest

COPY . /opt/arcusteam/app

WORKDIR /opt/arcusteam/app

RUN pip install flask mysql-connector-python flask-cors python-arango

RUN apt update; apt install at -y


CMD ["sh", "-c", "sleep 500"]

#ENTRYPOINT ["python"]

#CMD ["app.py"]
