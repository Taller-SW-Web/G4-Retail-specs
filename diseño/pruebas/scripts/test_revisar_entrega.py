import copy
import unittest
from revisar_entrega import revisar_backend, revisar_frontend, revisar_cobertura_backend, revisar_cobertura_frontend


class RevisionEntregaTest(unittest.TestCase):
    def backend(self):
        return [{'clase': 'Suite', 'ruta': 'src/test/Suite.java', 'cantidad': 1, 'casos': [
            {'grupo': 'grupo', 'nombre': 'caso', 'estado': 'aprobado', 'tipo': 'Integración'}]}]

    def frontend(self):
        return {'numTotalTests': 1, 'numPassedTests': 1, 'numFailedTests': 0, 'numPendingTests': 0,
                'success': True, 'testResults': [{'name': 'src/archivo.test.ts', 'status': 'passed',
                'assertionResults': [{'fullName': 'caso', 'status': 'passed', 'failureMessages': []}]}]}

    def test_backend_cuenta_casos_y_separa_tipos(self):
        self.assertEqual(revisar_backend(self.backend())['por_tipo'], {'Integración': 1})

    def test_backend_rechaza_duplicados_y_cantidad_manipulada(self):
        datos = self.backend()
        with self.assertRaises(ValueError):
            revisar_backend(datos + copy.deepcopy(datos))
        datos[0]['cantidad'] = 999
        with self.assertRaises(ValueError):
            revisar_backend(datos)

    def test_frontend_no_confia_en_success_sin_revisar_casos(self):
        datos = self.frontend()
        datos['testResults'][0]['assertionResults'][0]['status'] = 'failed'
        with self.assertRaises(ValueError):
            revisar_frontend(datos)

    def test_frontend_rechaza_error_no_asociado_a_caso(self):
        datos = self.frontend()
        datos['success'] = False
        with self.assertRaises(ValueError):
            revisar_frontend(datos)

    def test_no_aprueba_entrega_sin_casos(self):
        with self.assertRaises(ValueError):
            revisar_backend([])
        datos = self.frontend()
        datos.update(numTotalTests=0, numPassedTests=0, testResults=[])
        with self.assertRaises(ValueError):
            revisar_frontend(datos)

    def test_cobertura_backend_exige_suma_de_paquetes(self):
        datos = {'metricas': [{'tipo': 'LINE', 'cubiertos': 9, 'noCubiertos': 1}],
                 'paquetes': [{'paquete': 'paquete', 'metricas': [{'tipo': 'LINE', 'cubiertos': 9, 'noCubiertos': 1}]}]}
        self.assertEqual(revisar_cobertura_backend(datos)['LINE']['porcentaje'], 90)
        datos['paquetes'][0]['metricas'][0]['cubiertos'] = 8
        with self.assertRaises(ValueError):
            revisar_cobertura_backend(datos)

    def test_cobertura_frontend_verifica_porcentaje_y_contadores(self):
        contador = {'total': 3, 'covered': 2, 'pct': 66.66}
        datos = {'total': {k: dict(contador) for k in ['lines', 'branches', 'functions', 'statements']},
                 'src/a.ts': {k: dict(contador) for k in ['lines', 'branches', 'functions', 'statements']}}
        self.assertEqual(revisar_cobertura_frontend(datos)['lines']['covered'], 2)
        datos['total']['lines']['pct'] = 100
        with self.assertRaises(ValueError):
            revisar_cobertura_frontend(datos)

    def test_jacoco_no_inventa_ramas_para_paquetes_sin_ramas(self):
        datos = {'metricas': [{'tipo': 'BRANCH', 'cubiertos': 1, 'noCubiertos': 1}],
                 'paquetes': [{'paquete': 'sinRamas', 'metricas': []},
                              {'paquete': 'conRamas', 'metricas': [{'tipo': 'BRANCH', 'cubiertos': 1, 'noCubiertos': 1}]}]}
        self.assertEqual(revisar_cobertura_backend(datos)['BRANCH']['porcentaje'], 50)


if __name__ == '__main__':
    unittest.main()
