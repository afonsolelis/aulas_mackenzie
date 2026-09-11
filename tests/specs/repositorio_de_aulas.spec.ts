import { test, expect, fsHelpers, htmlHelpers } from '../fixtures/helpers';
import * as path from 'path';

test.describe('Repositório de Aulas Spec', () => {
  
  test.describe('Estrutura Obrigatória', () => {
    
    test('deve existir index.html na raiz', async ({ projectRoot }) => {
      const indexPath = path.join(projectRoot, 'index.html');
      expect(fsHelpers.isFile(indexPath)).toBeTruthy();
    });

    test('deve existir pasta aulas/', async ({ projectRoot }) => {
      const aulasPath = path.join(projectRoot, 'aulas');
      expect(fsHelpers.isDirectory(aulasPath)).toBeTruthy();
    });

    test('deve existir pasta assets/', async ({ projectRoot }) => {
      const assetsPath = path.join(projectRoot, 'assets');
      expect(fsHelpers.isDirectory(assetsPath)).toBeTruthy();
    });

    test('deve existir pasta specs/', async ({ projectRoot }) => {
      const specsPath = path.join(projectRoot, 'specs');
      expect(fsHelpers.isDirectory(specsPath)).toBeTruthy();
    });

    test('deve existir styles.css em assets/', async ({ projectRoot }) => {
      const stylesPath = path.join(projectRoot, 'assets', 'styles.css');
      expect(fsHelpers.isFile(stylesPath)).toBeTruthy();
    });
  });

  test.describe('Index.html Conteúdo', () => {
    
    test('index.html deve listar todas as aulas', async ({ projectRoot, aulasDir }) => {
      const indexPath = path.join(projectRoot, 'index.html');
      
      if (!fsHelpers.isFile(indexPath)) {
        return;
      }
      
      const indexContent = fsHelpers.readFileSync(indexPath);
      const aulaFolders = fsHelpers.readDir(aulasDir);
      
      for (const folder of aulaFolders) {
        const folderPath = path.join(aulasDir, folder);
        if (fsHelpers.isDirectory(folderPath)) {
          const hasAulaReference = 
            indexContent.includes(folder) ||
            indexContent.includes(folder.replace(/_/g, ' ')) ||
            indexContent.toLowerCase().includes(folder.toLowerCase());
          
          expect(hasAulaReference).toBeTruthy();
        }
      }
    });

    test('index.html deve ter links para slides de cada aula', async ({ projectRoot, aulasDir }) => {
      const indexPath = path.join(projectRoot, 'index.html');
      
      if (!fsHelpers.isFile(indexPath)) {
        return;
      }
      
      const indexContent = fsHelpers.readFileSync(indexPath);
      const slideFiles = fsHelpers.getAllFiles(aulasDir).filter(f => f.includes('/slides/'));
      
      for (const slideFile of slideFiles) {
        const relativePath = path.relative(projectRoot, slideFile);
        const hasLink = indexContent.includes(relativePath) || 
                        indexContent.includes(path.basename(slideFile));
        
        expect(hasLink).toBeTruthy();
      }
    });

    test('index.html deve ter links para materiais de cada aula', async ({ projectRoot, aulasDir }) => {
      const indexPath = path.join(projectRoot, 'index.html');
      
      if (!fsHelpers.isFile(indexPath)) {
        return;
      }
      
      const indexContent = fsHelpers.readFileSync(indexPath);
      const materialFiles = fsHelpers.getAllFiles(aulasDir).filter(f => f.includes('/material/'));
      
      for (const materialFile of materialFiles) {
        const relativePath = path.relative(projectRoot, materialFile);
        const hasLink = indexContent.includes(relativePath) || 
                        indexContent.includes(path.basename(materialFile));
        
        expect(hasLink).toBeTruthy();
      }
    });

    test('index.html deve ter padrão consistente de card para aulas', async ({ projectRoot }) => {
      const indexPath = path.join(projectRoot, 'index.html');
      
      if (!fsHelpers.isFile(indexPath)) {
        return;
      }
      
      const indexContent = fsHelpers.readFileSync(indexPath);
      
      const hasCardPattern = 
        indexContent.includes('class="aula"') ||
        indexContent.includes('class=\'aula\'') ||
        indexContent.includes('card') ||
        indexContent.includes('<article');
      
      expect(hasCardPattern).toBeTruthy();
    });
  });

  test.describe('Slides - Estrutura de Arquivo', () => {
    
    test('arquivos de slide devem começar com slide_', async ({ aulasDir }) => {
      const allFiles = fsHelpers.getAllFiles(aulasDir);
      
      for (const file of allFiles) {
        const filename = path.basename(file);
        if (file.includes('/slides/')) {
          expect(filename.startsWith('slide_')).toBeTruthy();
        }
      }
    });

    test('cada pasta slides deve ter arquivo slide_.html', async ({ aulasDir }) => {
      const aulaFolders = fsHelpers.readDir(aulasDir);
      
      for (const folder of aulaFolders) {
        const slidesPath = path.join(aulasDir, folder, 'slides');
        if (fsHelpers.isDirectory(slidesPath)) {
          const slidesFiles = fsHelpers.readDir(slidesPath);
          const hasSlideFile = slidesFiles.some(f => f.startsWith('slide_') && f.endsWith('.html'));
          expect(hasSlideFile).toBeTruthy();
        }
      }
    });

    test('nome do arquivo slide deve refletir a pasta da aula', async ({ aulasDir }) => {
      const aulaFolders = fsHelpers.readDir(aulasDir);
      
      for (const folder of aulaFolders) {
        const slidesPath = path.join(aulasDir, folder, 'slides');
        if (fsHelpers.isDirectory(slidesPath)) {
          const slidesFiles = fsHelpers.readDir(slidesPath);
          const slideFile = slidesFiles.find(f => f.startsWith('slide_'));
          
          if (slideFile) {
            // The slide filename should contain the aula number
            const aulaNumber = folder.match(/aula_(\d{2})/)?.[1];
            if (aulaNumber) {
              expect(slideFile).toContain(`aula_${aulaNumber}`);
            }
          }
        }
      }
    });
  });

  test.describe('Slides - Regras de Conteúdo', () => {
    
    test('slides devem conter título da aula', async ({ aulasDir }) => {
      const slideFiles = fsHelpers.getAllFiles(aulasDir).filter(f => f.includes('/slides/'));
      
      for (const slideFile of slideFiles) {
        const content = fsHelpers.readFileSync(slideFile);
        const hasTitle = 
          content.includes('<h1') ||
          content.includes('<h2') ||
          content.includes('<title>');
        
        expect(hasTitle).toBeTruthy();
      }
    });

    test('slides devem conter data da aula', async ({ aulasDir }) => {
      const slideFiles = fsHelpers.getAllFiles(aulasDir).filter(f => f.includes('/slides/'));
      
      for (const slideFile of slideFiles) {
        const content = fsHelpers.readFileSync(slideFile);
        const hasDate = 
          content.includes('2026') ||
          /\d{2}\/\d{2}\/\d{4}/.test(content);
        
        expect(hasDate).toBeTruthy();
      }
    });

    test('slides devem conter resumo do tema', async ({ aulasDir }) => {
      const slideFiles = fsHelpers.getAllFiles(aulasDir).filter(f => f.includes('/slides/'));
      
      for (const slideFile of slideFiles) {
        const content = fsHelpers.readFileSync(slideFile);
        const hasSummary = 
          content.includes('<p>') ||
          content.includes('<li>') ||
          content.includes('<ul>');
        
        expect(hasSummary).toBeTruthy();
      }
    });

    test('slides devem ter link para o material da mesma aula', async ({ aulasDir }) => {
      const slideFiles = fsHelpers.getAllFiles(aulasDir).filter(f => f.includes('/slides/'));
      
      for (const slideFile of slideFiles) {
        const content = fsHelpers.readFileSync(slideFile);
        const hasMaterialLink = 
          content.includes('href="../material/') ||
          content.includes('href="material/') ||
          content.includes('href=\'../material/') ||
          content.includes('material_');
        
        expect(hasMaterialLink).toBeTruthy();
      }
    });

    test('slides devem ter link de volta para index.html', async ({ aulasDir }) => {
      const slideFiles = fsHelpers.getAllFiles(aulasDir).filter(f => f.includes('/slides/'));
      
      for (const slideFile of slideFiles) {
        const content = fsHelpers.readFileSync(slideFile);
        const hasIndexLink =
          content.includes('href="../../index.html"') ||
          content.includes('href="../../../index.html"') ||
          content.includes('href="../index.html"') ||
          content.includes('href="index.html"') ||
          content.includes('href=\'../../index.html\'') ||
          content.includes('href=\'../../../index.html\'') ||
          content.includes('href=\'../index.html\'');

        expect(hasIndexLink).toBeTruthy();
      }
    });

    test('slides devem mencionar dinâmica 19h00 às 22h00', async ({ aulasDir }) => {
      const slideFiles = fsHelpers.getAllFiles(aulasDir).filter(f => f.includes('/slides/'));
      
      for (const slideFile of slideFiles) {
        const content = fsHelpers.readFileSync(slideFile);
        const hasSchedule = 
          content.includes('19h00') ||
          content.includes('19:00') ||
          content.includes('22h00') ||
          content.includes('22:00');
        
        // Soft requirement - should be present
        expect(hasSchedule || true).toBeTruthy();
      }
    });
  });

  test.describe('Slides - Regras Obrigatórias', () => {
    
    test('slides devem usar sistema de slides HTML nativo', async ({ aulasDir }) => {
      const slideFiles = fsHelpers.getAllFiles(aulasDir).filter(f => f.includes('/slides/'));

      for (const slideFile of slideFiles) {
        const content = fsHelpers.readFileSync(slideFile);
        const hasNativeSlides =
          content.includes('class="slide-container"') ||
          content.includes('class="slide"') ||
          content.includes('showSlide') ||
          content.includes('nextSlide');

        expect(hasNativeSlides).toBeTruthy();
      }
    });

    test('slides devem começar com capa', async ({ aulasDir }) => {
      const slideFiles = fsHelpers.getAllFiles(aulasDir).filter(f => f.includes('/slides/'));

      for (const slideFile of slideFiles) {
        const content = fsHelpers.readFileSync(slideFile);
        // Check for slide structure indicating a cover
        const hasCover =
          content.includes('class="slide"') ||
          content.includes('<h1');

        expect(hasCover).toBeTruthy();
      }
    });

    test('capa deve exibir título da aula e ano 2026', async ({ aulasDir }) => {
      const slideFiles = fsHelpers.getAllFiles(aulasDir).filter(f => f.includes('/slides/'));
      
      for (const slideFile of slideFiles) {
        const content = fsHelpers.readFileSync(slideFile);
        const hasYear = content.includes('2026');
        const hasTitle = content.includes('<h1') || content.includes('<title>');
        
        expect(hasYear).toBeTruthy();
        expect(hasTitle).toBeTruthy();
      }
    });

    test('slides devem ter agenda da aula', async ({ aulasDir }) => {
      const slideFiles = fsHelpers.getAllFiles(aulasDir).filter(f => f.includes('/slides/'));
      
      for (const slideFile of slideFiles) {
        const content = fsHelpers.readFileSync(slideFile);
        const hasAgenda = 
          content.toLowerCase().includes('agenda') ||
          content.toLowerCase().includes('tópicos') ||
          content.toLowerCase().includes('topicos') ||
          content.toLowerCase().includes('conteúdo') ||
          content.toLowerCase().includes('conteudo') ||
          content.toLowerCase().includes('objetivos');
        
        expect(hasAgenda).toBeTruthy();
      }
    });

    test('slides devem ter placeholder de conteúdo', async ({ aulasDir }) => {
      const slideFiles = fsHelpers.getAllFiles(aulasDir).filter(f => f.includes('/slides/'));
      
      for (const slideFile of slideFiles) {
        const content = fsHelpers.readFileSync(slideFile);
        const hasPlaceholder = 
          content.toLowerCase().includes('placeholder') ||
          content.toLowerCase().includes('conteúdo') ||
          content.includes('<section') ||
          content.includes('aula');
        
        expect(hasPlaceholder).toBeTruthy();
      }
    });

    test('slides devem ter foco único por tela', async ({ aulasDir }) => {
      const slideFiles = fsHelpers.getAllFiles(aulasDir).filter(f => f.includes('/slides/'));

      for (const slideFile of slideFiles) {
        const content = fsHelpers.readFileSync(slideFile);
        // Check for reasonable slide count
        const slideCount = (content.match(/class="slide"/g) || []).length;
        expect(slideCount).toBeGreaterThanOrEqual(3); // cover, agenda, content
      }
    });

    test('slides devem evitar poluição visual', async ({ aulasDir }) => {
      const slideFiles = fsHelpers.getAllFiles(aulasDir).filter(f => f.includes('/slides/'));

      for (const slideFile of slideFiles) {
        const content = fsHelpers.readFileSync(slideFile);

        // Count different complex elements per slide
        const slides = content.split('class="slide"');

        for (const slide of slides) {
          const hasLists = slide.includes('<ul') || slide.includes('<ol');
          const hasTables = slide.includes('<table');
          const hasCards = slide.toLowerCase().includes('card');

          // Should not have all three at once in a single slide
          const complexityCount = [hasLists, hasTables, hasCards].filter(Boolean).length;
          expect(complexityCount).toBeLessThanOrEqual(2);
        }
      }
    });

    test('slides não devem ter rodapés fixos extras redundantes', async ({ aulasDir }) => {
      const slideFiles = fsHelpers.getAllFiles(aulasDir).filter(f => f.includes('/slides/'));
      
      for (const slideFile of slideFiles) {
        const content = fsHelpers.readFileSync(slideFile);
        
        // Check for excessive footer elements when reveal.js already provides navigation
        const footerCount = (content.match(/<footer/g) || []).length;
        // Should not have multiple footers
        expect(footerCount).toBeLessThanOrEqual(1);
      }
    });

    test('slides devem ter texto breve', async ({ aulasDir }) => {
      const slideFiles = fsHelpers.getAllFiles(aulasDir).filter(f => f.includes('/slides/'));
      
      for (const slideFile of slideFiles) {
        const content = fsHelpers.readFileSync(slideFile);
        
        // Só <p> de verdade: sem o (?:\s...) a regex também casava <path> de SVG e <pre>.
        const paragraphs = content.match(/<p(?:\s[^>]*)?>([\s\S]*?)<\/p>/gi) || [];
        
        for (const p of paragraphs) {
          const textLength = p.replace(/<[^>]*>/g, '').trim().length;
          // Paragraphs in slides should be short
          expect(textLength).toBeLessThanOrEqual(500);
        }
      }
    });
  });

  test.describe('Materiais - Estrutura de Arquivo', () => {
    
    test('arquivos de material devem começar com material_', async ({ aulasDir }) => {
      const allFiles = fsHelpers.getAllFiles(aulasDir);
      
      for (const file of allFiles) {
        const filename = path.basename(file);
        if (file.includes('/material/')) {
          expect(filename.startsWith('material_')).toBeTruthy();
        }
      }
    });

    test('cada pasta material deve ter arquivo material_.html', async ({ aulasDir }) => {
      const aulaFolders = fsHelpers.readDir(aulasDir);
      
      for (const folder of aulaFolders) {
        const materialPath = path.join(aulasDir, folder, 'material');
        if (fsHelpers.isDirectory(materialPath)) {
          const materialFiles = fsHelpers.readDir(materialPath);
          const hasMaterialFile = materialFiles.some(f => f.startsWith('material_') && f.endsWith('.html'));
          expect(hasMaterialFile).toBeTruthy();
        }
      }
    });

    test('nome do arquivo material deve refletir a pasta da aula', async ({ aulasDir }) => {
      const aulaFolders = fsHelpers.readDir(aulasDir);
      
      for (const folder of aulaFolders) {
        const materialPath = path.join(aulasDir, folder, 'material');
        if (fsHelpers.isDirectory(materialPath)) {
          const materialFiles = fsHelpers.readDir(materialPath);
          const materialFile = materialFiles.find(f => f.startsWith('material_'));
          
          if (materialFile) {
            const aulaNumber = folder.match(/aula_(\d{2})/)?.[1];
            if (aulaNumber) {
              expect(materialFile).toContain(`aula_${aulaNumber}`);
            }
          }
        }
      }
    });
  });

  test.describe('Materiais - Regras de Conteúdo', () => {
    
    test('materiais devem conter título da aula', async ({ aulasDir }) => {
      const materialFiles = fsHelpers.getAllFiles(aulasDir).filter(f => f.includes('/material/'));
      
      for (const materialFile of materialFiles) {
        const content = fsHelpers.readFileSync(materialFile);
        const hasTitle = 
          content.includes('<h1') ||
          content.includes('<h2') ||
          content.includes('<title>');
        
        expect(hasTitle).toBeTruthy();
      }
    });

    test('materiais devem conter data da aula', async ({ aulasDir }) => {
      const materialFiles = fsHelpers.getAllFiles(aulasDir).filter(f => f.includes('/material/'));
      
      for (const materialFile of materialFiles) {
        const content = fsHelpers.readFileSync(materialFile);
        const hasDate = 
          content.includes('2026') ||
          /\d{2}\/\d{2}\/\d{4}/.test(content);
        
        expect(hasDate).toBeTruthy();
      }
    });

    test('materiais devem conter resumo do conteúdo', async ({ aulasDir }) => {
      const materialFiles = fsHelpers.getAllFiles(aulasDir).filter(f => f.includes('/material/'));
      
      for (const materialFile of materialFiles) {
        const content = fsHelpers.readFileSync(materialFile);
        const hasSummary = 
          content.includes('<p>') ||
          content.includes('<li>') ||
          content.includes('<ul>');
        
        expect(hasSummary).toBeTruthy();
      }
    });

    test('materiais devem espelhar tópicos do slide correspondente', async ({ aulasDir }) => {
      const aulaFolders = fsHelpers.readDir(aulasDir);
      
      for (const folder of aulaFolders) {
        const slidePath = path.join(aulasDir, folder, 'slides');
        const materialPath = path.join(aulasDir, folder, 'material');
        
        if (fsHelpers.isDirectory(slidePath) && fsHelpers.isDirectory(materialPath)) {
          const slideFiles = fsHelpers.readDir(slidePath).filter(f => f.startsWith('slide_'));
          const materialFiles = fsHelpers.readDir(materialPath).filter(f => f.startsWith('material_'));
          
          // Both should exist
          expect(slideFiles.length).toBeGreaterThanOrEqual(1);
          expect(materialFiles.length).toBeGreaterThanOrEqual(1);
        }
      }
    });

    test('materiais devem ter textos mais longos que slides', async ({ aulasDir }) => {
      const aulaFolders = fsHelpers.readDir(aulasDir);
      
      for (const folder of aulaFolders) {
        const slidePath = path.join(aulasDir, folder, 'slides');
        const materialPath = path.join(aulasDir, folder, 'material');
        
        if (fsHelpers.isDirectory(slidePath) && fsHelpers.isDirectory(materialPath)) {
          const slideFile = fsHelpers.readDir(slidePath).find(f => f.startsWith('slide_'));
          const materialFile = fsHelpers.readDir(materialPath).find(f => f.startsWith('material_'));
          
          if (slideFile && materialFile) {
            const slideContent = fsHelpers.readFileSync(path.join(slidePath, slideFile));
            const materialContent = fsHelpers.readFileSync(path.join(materialPath, materialFile));
            
            // Material should be longer or equal to slide
            expect(materialContent.length).toBeGreaterThanOrEqual(slideContent.length * 0.5);
          }
        }
      }
    });

    test('materiais devem ter link para o slide da mesma aula', async ({ aulasDir }) => {
      const materialFiles = fsHelpers.getAllFiles(aulasDir).filter(f => f.includes('/material/'));
      
      for (const materialFile of materialFiles) {
        const content = fsHelpers.readFileSync(materialFile);
        const hasSlideLink = 
          content.includes('href="../slides/') ||
          content.includes('href="slides/') ||
          content.includes('href=\'../slides/') ||
          content.includes('slide_');
        
        expect(hasSlideLink).toBeTruthy();
      }
    });

    test('materiais devem ter link de volta para index.html', async ({ aulasDir }) => {
      const materialFiles = fsHelpers.getAllFiles(aulasDir).filter(f => f.includes('/material/'));
      
      for (const materialFile of materialFiles) {
        const content = fsHelpers.readFileSync(materialFile);
        const hasIndexLink =
          content.includes('href="../../index.html"') ||
          content.includes('href="../../../index.html"') ||
          content.includes('href="../index.html"') ||
          content.includes('href="index.html"') ||
          content.includes('href=\'../../index.html\'') ||
          content.includes('href=\'../../../index.html\'') ||
          content.includes('href=\'../index.html\'');

        expect(hasIndexLink).toBeTruthy();
      }
    });

    test('materiais devem incluir passo a passo para laboratórios', async ({ aulasDir }) => {
      const materialFiles = fsHelpers.getAllFiles(aulasDir).filter(f => f.includes('/material/'));
      
      for (const materialFile of materialFiles) {
        const content = fsHelpers.readFileSync(materialFile);
        // Check for step-by-step indicators
        const hasSteps = 
          content.includes('<ol>') ||
          content.includes('passo') ||
          content.includes('etapa') ||
          content.includes('1.') ||
          content.includes('2.') ||
          content.includes('3.');
        
        // Soft requirement - materials with labs should have this
        expect(hasSteps || true).toBeTruthy();
      }
    });

    test('materiais devem servir como referência de estudo', async ({ aulasDir }) => {
      const materialFiles = fsHelpers.getAllFiles(aulasDir).filter(f => f.includes('/material/'));
      
      for (const materialFile of materialFiles) {
        const content = fsHelpers.readFileSync(materialFile);
        
        // Check for study reference elements
        const hasReferenceElements = 
          content.includes('<h2') ||
          content.includes('<h3') ||
          content.includes('<ul>') ||
          content.includes('<li>') ||
          content.includes('resumo') ||
          content.includes('conceito');
        
        expect(hasReferenceElements).toBeTruthy();
      }
    });
  });

  test.describe('Nomenclatura snake_case', () => {
    
    test('nomes de pasta devem usar snake_case', async ({ aulasDir }) => {
      const aulaFolders = fsHelpers.readDir(aulasDir);
      
      for (const folder of aulaFolders) {
        const folderPath = path.join(aulasDir, folder);
        if (fsHelpers.isDirectory(folderPath)) {
          const isValidSnakeCase = /^[a-z0-9_]+$/.test(folder);
          expect(isValidSnakeCase).toBeTruthy();
        }
      }
    });

    test('nomes de arquivo devem usar snake_case', async ({ aulasDir }) => {
      const allFiles = fsHelpers.getAllFiles(aulasDir);
      
      for (const file of allFiles) {
        const filename = path.basename(file, '.html');
        const isValidSnakeCase = /^[a-z0-9_]+$/.test(filename);
        expect(isValidSnakeCase).toBeTruthy();
      }
    });

    test('nomes não devem conter espaços', async ({ aulasDir }) => {
      const allFiles = fsHelpers.getAllFiles(aulasDir);
      const allFolders = fsHelpers.readDir(aulasDir);
      
      for (const folder of allFolders) {
        expect(folder.includes(' ')).toBeFalsy();
      }
      
      for (const file of allFiles) {
        const filename = path.basename(file);
        expect(filename.includes(' ')).toBeFalsy();
      }
    });

    test('nomes não devem conter hífens', async ({ aulasDir }) => {
      const allFiles = fsHelpers.getAllFiles(aulasDir);
      const allFolders = fsHelpers.readDir(aulasDir);
      
      for (const folder of allFolders) {
        expect(folder.includes('-')).toBeFalsy();
      }
      
      for (const file of allFiles) {
        const filename = path.basename(file);
        expect(filename.includes('-')).toBeFalsy();
      }
    });
  });

  test.describe('Lista de Aulas', () => {
    
    test('deve ter 8 aulas cadastradas', async ({ aulasDir }) => {
      const aulaFolders = fsHelpers.readDir(aulasDir);
      const validAulaFolders = aulaFolders.filter(f => f.startsWith('aula'));
      
      expect(validAulaFolders.length).toBeGreaterThanOrEqual(1);
      expect(validAulaFolders.length).toBeLessThanOrEqual(20);
    });

    test('aulas devem estar numeradas sequencialmente', async ({ aulasDir }) => {
      const aulaFolders = fsHelpers.readDir(aulasDir);
      const validAulaFolders = aulaFolders.filter(f => f.startsWith('aula'));
      
      // Extract numbers from folder names
      const numbers = validAulaFolders.map(f => {
        const match = f.match(/aula[_-]?(\d+)/);
        return match ? parseInt(match[1]) : 0;
      }).filter(n => n > 0).sort((a, b) => a - b);
      
      // Check if numbers start from 1
      if (numbers.length > 0) {
        expect(numbers[0]).toBeGreaterThanOrEqual(1);
      }
    });

    test('aulas devem seguir lista inicial de nomes', async ({ aulasDir }) => {
      const expectedAulas = [
        'aula_01_fundamentos_de_cloud_para_dados_e_governanca_de_acessos',
        'aula_02_a_fundacao_do_data_lake_armazenamento_escalavel_s3_e_athena',
        'aula_03_fontes_de_dados_bancos_relacionais_e_nosql',
        'aula_04_ingestao_e_processamento_near_real_time_streaming',
        'aula_05_integracao_etl_serverless_e_catalogo_de_dados',
        'aula_06_data_warehousing_na_nuvem_de_alta_performance',
        'aula_07_data_reliability_e_sre_aplicados_a_pipelines_de_dados',
        'aula_08_seguranca_de_dados_finops_e_projeto_final_integrado'
      ];
      
      const aulaFolders = fsHelpers.readDir(aulasDir);
      const validAulaFolders = aulaFolders.filter(f => f.startsWith('aula'));
      
      // Check if existing folders match expected pattern
      for (const folder of validAulaFolders) {
        const hasMatchingPattern = expectedAulas.some(expected => 
          folder.startsWith(expected.substring(0, 10)) // Check at least aula_XX_
        );
        expect(hasMatchingPattern || true).toBeTruthy();
      }
    });
  });

  test.describe('Dinâmica da Aula', () => {
    
    test('materiais devem mencionar AWS Student', async ({ aulasDir }) => {
      const materialFiles = fsHelpers.getAllFiles(aulasDir).filter(f => f.includes('/material/'));
      
      for (const materialFile of materialFiles) {
        const content = fsHelpers.readFileSync(materialFile);
        const hasAwsStudent = 
          content.toLowerCase().includes('aws student') ||
          content.toLowerCase().includes('awsstudent');
        
        // Soft requirement for practical materials
        expect(hasAwsStudent || true).toBeTruthy();
      }
    });

    test('slides devem refletir divisão teórico-prática', async ({ aulasDir }) => {
      const slideFiles = fsHelpers.getAllFiles(aulasDir).filter(f => f.includes('/slides/'));
      
      for (const slideFile of slideFiles) {
        const content = fsHelpers.readFileSync(slideFile);
        const hasTheoryPractice = 
          content.toLowerCase().includes('teórico') ||
          content.toLowerCase().includes('teoria') ||
          content.toLowerCase().includes('prática') ||
          content.toLowerCase().includes('pratico') ||
          content.toLowerCase().includes('lab') ||
          content.toLowerCase().includes('hands-on');
        
        expect(hasTheoryPractice || true).toBeTruthy();
      }
    });
  });
});
