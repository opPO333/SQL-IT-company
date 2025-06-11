from flask_appbuilder.security.sqla.models import User
from flask_appbuilder.security.sqla.manager import SecurityManager
from sqlalchemy import Table, MetaData, Column, Integer, String, Date, and_, null, ForeignKey
from sqlalchemy.orm import relationship
from .models import MyUser
from flask_babel import lazy_gettext
from flask_appbuilder.security.views import UserDBModelView
from flask import g, flash, redirect, url_for, abort


class MyUserDBModelView(UserDBModelView):
    show_fieldsets = [
        (lazy_gettext('User info'),
         {'fields': ['username', 'active', 'roles', 'login_count', 'extra']}),
        (lazy_gettext('Personal Info'),
         {'fields': ['first_name', 'last_name', 'email'], 'expanded': True}),
        (lazy_gettext('Audit Info'),
         {'fields': ['last_login', 'fail_login_count', 'created_on',
                     'created_by', 'changed_on', 'changed_by'], 'expanded': False}),
    ]

    user_show_fieldsets = [
        (lazy_gettext('User info'),
         {'fields': ['username', 'active', 'roles', 'login_count', 'extra']}),
        (lazy_gettext('Personal Info'),
         {'fields': ['first_name', 'last_name', 'email'], 'expanded': True}),
    ]

    add_columns = [
        'username',
        'active',
        'email',
        'roles',
        'employee',
        'password',
        'conf_password'
    ]
    list_columns = [
        'first_name',
        'last_name',
        'username',
        'email',
        'active',
        'roles',
    ]
    edit_columns = [
        'first_name',
        'last_name',
        'username',
        'active',
        'email',
        'roles',
        'employee'
    ]
    def post_update(self, item):
        if item.employee:
            item.employee.first_name = item.first_name
            item.employee.second_name = item.second_name
    def pre_update(self, item):
        if g.user.is_admin():
            return

        if item.id != g.user.id:
            abort(403)





class MySecurityManager(SecurityManager):
    user_model = MyUser
    userdbmodelview = MyUserDBModelView
    def __init__(self, appbuilder):
        super(MySecurityManager, self).__init__(appbuilder)

