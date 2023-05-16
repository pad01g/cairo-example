from setuptools import setup

setup(
    name="rfc6979",
    version="0.0.1",
    install_requires=["secp256k1"],
    extras_require={},
    entry_points={
        "console_scripts": [
            "foo = package_name.module_name:func_name",
            "foo_dev = package_name.module_name:func_name [develop]"
        ],
        "gui_scripts": [
            "bar = gui_package_name.gui_module_name:gui_func_name"
        ]
    }
)
