FROM python
RUN pip install exoscale
COPY autoscaler.py /
ENTRYPOINT ["python", "/autoscaler.py"]