from app.ui import ui
import flask
from flask import Flask, url_for, render_template, request, redirect, session, flash
import os
from functools import wraps
from passlib.hash import sha256_crypt

# Check if user logged in
def is_logged_in(f):
    @wraps(f)
    def wrap(*args, **kwargs):
        if 'logged_in' in session:
            return f(*args, **kwargs)
        else:
            flash('Unauthorized, Please login', 'red')
            return redirect(url_for('ui.login'))
    return wrap


@ui.route('/',  methods=['GET', 'POST'])
@is_logged_in
def index():
    """
    Delivers the home page of Nginx UI.

    :return: Rendered HTML document.
    :rtype: str
    """
    nginx_path = flask.current_app.config['NGINX_PATH']
    config = [f for f in os.listdir(nginx_path) if os.path.isfile(os.path.join(nginx_path, f))]
    return flask.render_template('index.html', config=config)


@ui.route('/login', methods=['GET', 'POST'])
def login():
    """Login Form"""
    if request.method == 'GET':
        return render_template('login.html')
    else:
        name = request.form['username']
        pass_form= request.form['password']
        try:
            user = flask.current_app.config['USER']
            if name == user:
                pswd = flask.current_app.config['PASS']
                if sha256_crypt.verify(pass_form, pswd):
                    session['logged_in'] = True
                    return redirect(url_for('ui.index'))
                else:
                    flash("Login incorrect ! Please try again.",'red')
                    session.clear()
                    return flask.render_template('login.html')
            else:
                flash("Login incorrect ! Please try again.",'red')
                session.clear()
                return flask.render_template('login.html')
        except:
            session.clear()
            flash("Error ! Please try again.",'red')
            return flask.render_template('login.html')


@ui.route("/logout")
def logout():
    """Logout Form"""
    session.clear()
    return render_template('login.html')
