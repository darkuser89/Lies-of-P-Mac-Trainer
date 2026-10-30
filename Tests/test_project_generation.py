#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-only
"""Temporary generated-project fixture; no game or app launch."""
from pathlib import Path
import json
import subprocess
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]

class ProjectGenerationTests(unittest.TestCase):
    def test_ui_modules_and_instructions_are_inherited(self):
        with tempfile.TemporaryDirectory(prefix='mactrainer-generation-') as folder:
            destination = Path(folder) / 'Generated'
            subprocess.run([sys.executable, '-B', str(ROOT / 'script/create_project.py'),
                            str(destination), '--name', 'Fixture Trainer',
                            '--bundle-id', 'local.fixture.trainer'], check=True,
                           capture_output=True, text=True)
            for relative in ['Sources/TrainerMaterial.h', 'Sources/TrainerMaterial.m',
                             'Sources/Overlay.m', 'Tests/PresentationTests.m',
                             'Tests/test_project_generation.py', 'docs/UI.md', 'SKILL.md']:
                self.assertEqual((destination / relative).read_bytes(),
                                 (ROOT / relative).read_bytes(), relative)
            config = json.loads((destination / 'Resources/TrainerConfig.json').read_text())
            self.assertEqual(config['app']['name'], 'Fixture Trainer')
            self.assertEqual(config['app']['version'], '0.1.0')
            self.assertTrue(all(not p['enabled'] and not p['uuids'] for p in config['profiles']))
            self.assertIn('docs/UI.md', (destination / 'SKILL.md').read_text())
            self.assertIn('Sources/TrainerMaterial.m',
                          (destination / 'script/build_and_run.sh').read_text())
            self.assertFalse((destination / '.git').exists())
            self.assertFalse(any(destination.rglob('*.app')))
            self.assertFalse(any(destination.rglob('*.dylib')))

if __name__ == '__main__':
    unittest.main()
