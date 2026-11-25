import tempfile
import unittest
from pathlib import Path
from consolidar import leer_junit, resumir


class PruebasConsolidacion(unittest.TestCase):
    def reporte(self, contenido):
        temporal = tempfile.TemporaryDirectory()
        self.addCleanup(temporal.cleanup)
        archivo = Path(temporal.name) / 'TEST-prueba.xml'
        archivo.write_text(contenido, encoding='utf-8')
        return archivo

    def test_cuenta_fallos_errores_y_omitidos_sin_confiar_en_totales_declarados(self):
        archivo = self.reporte('''<testsuites><testsuite tests="999">
          <testcase classname="Suite" name="bien" time="0.1"/>
          <testcase classname="Suite" name="fallo"><failure/></testcase>
          <testcase classname="Suite" name="error"><error/></testcase>
          <testcase classname="Suite" name="omitido"><skipped/></testcase>
        </testsuite></testsuites>''')
        datos = resumir(leer_junit([archivo]))
        self.assertEqual(datos['casos'], 4)
        self.assertEqual(datos['fallos'], 1)
        self.assertEqual(datos['errores'], 1)
        self.assertEqual(datos['omitidos'], 1)
        self.assertFalse(datos['aprobado'])

    def test_reporte_vacio_no_se_aprueba(self):
        self.assertFalse(resumir([])['aprobado'])

    def test_no_duplica_mismo_caso_de_dos_ejecuciones(self):
        archivo = self.reporte('<testsuite><testcase classname="Suite" name="caso"/></testsuite>')
        with self.assertRaisesRegex(ValueError, 'duplicado'):
            leer_junit([archivo, archivo])

    def test_todos_omitidos_no_se_aprueba(self):
        archivo = self.reporte('<testsuite><testcase classname="Suite" name="caso"><skipped/></testcase></testsuite>')
        self.assertFalse(resumir(leer_junit([archivo]))['aprobado'])

    def test_error_de_arranque_de_suite_no_se_presenta_como_aprobacion(self):
        archivo = self.reporte('<testsuite errors="1"><testcase classname="Suite" name="caso"/></testsuite>')
        with self.assertRaisesRegex(ValueError, 'sin caso asociado'):
            leer_junit([archivo])


if __name__ == '__main__':
    unittest.main()
