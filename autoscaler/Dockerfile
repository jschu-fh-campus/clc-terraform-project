FROM python
RUN pip install exoscale
RUN pip install flask
COPY autoscaler.py /
ENTRYPOINT ["python", "/autoscaler.py"]