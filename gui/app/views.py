from flask import render_template
from flask_appbuilder.models.sqla.interface import SQLAInterface
from flask_appbuilder import ModelView, ModelRestApi
from .models import Employee, Department, Team
import json
import datetime

from . import appbuilder, db

"""
    Create your Model based REST API::

    class MyModelApi(ModelRestApi):
        datamodel = SQLAInterface(MyModel)

    appbuilder.add_api(MyModelApi)


    Create your Views::


    class MyModelView(ModelView):
        datamodel = SQLAInterface(MyModel)


    Next, register your Views::


    appbuilder.add_view(
        MyModelView,
        "My View",
        icon="fa-folder-open-o",
        category="My Category",
        category_icon='fa-envelope'
    )
"""

"""
    Application wide 404 error handler
"""


@appbuilder.app.errorhandler(404)
def page_not_found(e):
    return (
        render_template(
            "404.html", base_template=appbuilder.base_template, appbuilder=appbuilder
        ),
        404,
    )
class EmployeeView(ModelView):
    datamodel = SQLAInterface(Employee)
    list_columns = ['first_name', 'last_name']
class DepartmentView(ModelView):
    datamodel = SQLAInterface(Department)
    list_columns = ['name']
    related_views = [EmployeeView]
    show_template = "appbuilder/general/model/show_cascade.html"

class TeamView(ModelView):
    datamodel = SQLAInterface(Team)
    list_columns = ['id']
    related_views = [EmployeeView]
    show_template = "appbuilder/general/model/show_cascade.html"


appbuilder.add_view(
    EmployeeView,
    "Employees"
    , icon="fa-users",
    category="Company",
    category_icon='fa-building')
appbuilder.add_view(
    DepartmentView,
    "Departments"
    , icon="fa-building",
    category="Company",
    category_icon='fa-building')
appbuilder.add_view(
    TeamView,
    "Teams"
    , icon="fa-building",
    category="Company",
    category_icon='fa-building'
)

db.create_all()
