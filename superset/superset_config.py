import os

SECRET_KEY = os.environ.get('SUPERSET_SECRET_KEY', 'superset')

SQLALCHEMY_DATABASE_URI = 'postgresql+psycopg2://analyst:analyst123@postgres:5432/oil_gas_db'

SUPERSET_WEBSERVER_PORT = 8088

FEATURE_FLAGS = {
    "EMBEDDABLE_CHARTS": True,
    "ALERT_REPORTS": True,
    "DASHBOARD_NATIVE_FILTERS": True,
    "DRILL_BY": True,
}

ROW_LIMIT = 100000