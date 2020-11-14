FROM python
RUN pip install exoscale
COPY service-discovery.py /
ENTRYPOINT ["python", "/service-discovery.py"]