import os


class Config(object):
    SECRET_KEY = os.urandom(64).hex()

    NGINX_PATH = '/etc/nginx'
    CONFIG_PATH = os.path.join(NGINX_PATH, 'conf.d')
    USER = "shyju"
    PASS = "$5$rounds=535000$9GtAKpf2HLK7e9TT$2sPe.jLQaz92Sx0pcoTdVWLzh3Zx/j7uHkqF3qtcp7/"
    
    @staticmethod
    def init_app(app):
        pass


class DevConfig(Config):
    DEBUG = False


class WorkingConfig(Config):
    DEBUG = False


config = {
    'dev': DevConfig,
    'default': WorkingConfig
}
