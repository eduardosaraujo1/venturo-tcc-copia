const express = require("express");
const cors = require("cors"); // <--- 1. Importação do CORS
const mysql = require("mysql2/promise");
const app = express();
const port = 8000;

app.use(cors({ origin: "*" }));
0;
app.use(express.json());

const dbConfig = {
    host: "localhost",
    user: "root",
    password: "root",
    database: "AppNidus",
};

let pool;

async function connectToDatabase() {
    try {
        pool = await mysql.createPool(dbConfig);
        console.log("Conexão com o MySQL estabelecida com sucesso!");
    } catch (error) {
        console.error("Falha ao conectar ao MySQL:", error);
    }
}

connectToDatabase();

// --- 2. ENDPOINT PARA OBTER TODOS OS USUÁRIOS (READ) ---
// ... (seu app.get('/api/usuarios', ...))

// --- 3. ENDPOINT PARA CRIAR UM NOVO USUÁRIO (CREATE) ---
// ... (seu app.post('/api/usuarios', ...))

app.post("/api/paciente/cadastrocompleto", async (req, res) => {
    // 1. Início do bloco try...catch para tratar erros assíncronos
    try {
        const {
            nome,
            idade,
            email,
            senha, // Idade está sendo extraída do corpo
            peso,
            tipo_sanguineo,
            comorbidade,
        } = req.body;

        // 2. Validação básica
        if (!nome || !tipo_sanguineo) {
            // Verifica se as variáveis estão presentes no corpo da requisição.
            return res.status(400).json({ error: "Nome e Tipo Sanguíneo são obrigatórios." });
        }

        const nomeTabela = "pacientes"; // Variável de nome de tabela

        // 3. Preparar a query SQL
        // CORREÇÃO 1: Usar template literals (`) para incluir nomeTabela (ou concatenar)
        // CORREÇÃO 2: Incluir 'idade' na lista de colunas da INSERT
        const sql = `
    INSERT INTO ${nomeTabela} 
    (nome, idade, email, peso, senha, tipo_sanguineo, comorbidade) 
    VALUES (?, ?, ?, ?, ?, ?, ?)
`;

        // CORREÇÃO 3: O array de parâmetros deve incluir a 'idade' e seguir a ordem exata das colunas na query.
        const parametros = [
            nome,
            idade, // 2ª coluna na SQL é 'idade', 2º parâmetro deve ser 'idade'
            email, // 3ª coluna na SQL é 'email', 3º parâmetro deve ser 'email'
            peso,
            senha, // 5ª coluna na SQL é 'senha', 5º parâmetro deve ser 'senha'
            tipo_sanguineo,
            comorbidade,
        ];

        // Execução da query
        const [result] = await pool.execute(sql, parametros);

        // 5. Resposta de sucesso
        res.status(201).json({
            id: result.insertId,
            // CORREÇÃO 4: A mensagem de sucesso deve indicar o nome do paciente, não 'paciente_id nome'.
            message: `Paciente ${nome} cadastrado com sucesso!`,
        });
    } catch (error) {
        // 6. Tratamento de erro

        // CORREÇÃO 5: O erro 'ER_DUP_ENTRY' pode ocorrer em qualquer coluna UNIQUE (e-mail, CPF, etc.),
        // mas o erro retornado no código original mencionava 'email'. Ajustei a mensagem.
        if (error.code === "ER_DUP_ENTRY") {
            return res
                .status(409)
                .json({ error: "Um registro com o campo único (ex: CPF, ID, etc.) fornecido já existe." });
        }

        // CORREÇÃO 6: A mensagem de erro interna mencionava 'cuidador', mas o endpoint é 'paciente'.
        console.error("Erro ao registrar cadastro do paciente:", error);
        res.status(500).json({ error: "Erro interno do servidor ao salvar dados do paciente." });
    }
});
// --- ROTA POST: /api/familiar/login ---
// ==========================================================
app.post("/api/familiar/login", async (req, res) => {
    const { identificador, senha } = req.body;
    const nomeTabela = "familiares";

    if (!identificador || !senha) {
        return res.status(400).json({ error: "Email/Telefone e senha são obrigatórios." });
    }

    try {
        // 1. Busca o usuário por email OU telefone, selecionando a senha de TEXTO PURO
        const [rows] = await pool.execute(`SELECT id, nome, senha FROM ${nomeTabela} WHERE email = ? OR telefone = ?`, [
            identificador,
            identificador,
        ]);

        // 2. Verifica se o usuário foi encontrado
        if (rows.length === 0) {
            return res.status(401).json({ error: "Credenciais inválidas." });
        }

        const familiar = rows[0];
        const senhaValida = senha === familiar.senha;
        if (!senhaValida) {
            return res.status(401).json({ error: "Credenciais inválidas." });
        }

        res.status(200).json({
            message: "Login bem-sucedido!",
            familiar_id: familiar.id,
            nome: familiar.nome,
        });
    } catch (error) {
        console.error("Erro no login do familiar:", error);
        res.status(500).json({ error: "Erro interno do servidor durante o login." });
    }
});

app.post("/api/familiar/cadastro", async (req, res) => {
    // 1. Extração dos dados enviados pelo Flutter
    const { nome, email, telefone, endereco, data_nascimento, genero, senha } = req.body;

    // 2. Validação de campos obrigatórios
    if (!nome || !email || !senha) {
        return res.status(400).json({ error: "Nome, email e senha são obrigatórios." });
    }

    const nomeTabela = "familiares";

    try {
        // 4. Executa a inserção no banco de dados
        // ATENÇÃO: A ordem das colunas e dos valores deve ser a mesma!
        const [result] = await pool.execute(
            `INSERT INTO ${nomeTabela} (nome, email, telefone, endereco, data_nascimento, genero, senha) VALUES (?, ?, ?, ?, ?, ?, ?)`,
            [nome, email, telefone, endereco, data_nascimento, genero, senha]
        );

        // 5. Resposta de sucesso
        res.status(201).json({
            id: result.insertId,
            message: `Familiar ${nome} cadastrado com sucesso!`,
        });
    } catch (error) {
        // 6. Tratamento de erro (ex: email duplicado)
        if (error.code === "ER_DUP_ENTRY") {
            return res.status(409).json({ error: "O email fornecido já está em uso." });
        }
        console.error("Erro ao registrar cadastro do familiar:", error);
        res.status(500).json({ error: "Erro interno do servidor ao salvar dados de familiar." });
    }
});

app.post("/api/cuidador/cadastro", async (req, res) => {
    // 1. Extração dos dados enviados pelo Flutter
    const { nome, email, telefone, endereco, data_nascimento, genero, senha } = req.body;

    // 2. Validação de campos obrigatórios
    if (!nome || !email || !senha) {
        return res.status(400).json({ error: "Nome, email e senha são obrigatórios." });
    }

    const nomeTabela = "cuidador";

    try {
        // 4. Executa a inserção no banco de dados
        // ATENÇÃO: A ordem das colunas e dos valores deve ser a mesma!
        const [result] = await pool.execute(
            `INSERT INTO ${nomeTabela} (nome, email, telefone, endereco, data_nascimento, genero, senha) VALUES (?, ?, ?, ?, ?, ?, ?)`,
            [nome, email, telefone, endereco, data_nascimento, genero, senha]
        );

        // 5. Resposta de sucesso
        res.status(201).json({
            id: result.insertId,
            message: `Familiar ${nome} cadastrado com sucesso!`,
        });
    } catch (error) {
        // 6. Tratamento de erro (ex: email duplicado)
        if (error.code === "ER_DUP_ENTRY") {
            return res.status(409).json({ error: "O email fornecido já está em uso." });
        }
        console.error("Erro ao registrar cadastro do cuidador:", error);
        res.status(500).json({ error: "Erro interno do servidor ao salvar dados de cuidador." });
    }
});

// IMPORTANTE: Este código assume que você tem o Express e o pool de conexão do MySQL configurados.
// Certifique-se de que a middleware 'express.json()' está ativa no seu servidor:
// app.use(express.json());

app.post("/api/cuidador/profissional", async (req, res) => {
    // 1. Dados de texto vêm do corpo da requisição JSON (req.body)
    const { cuidador_id, formacao, registro_profissional, declaracao_apto } = req.body;

    // 2. Validação dos campos obrigatórios
    // O Flutter envia 'declaracao_apto' como booleano (true/false)
    if (!cuidador_id || !formacao || declaracao_apto !== true) {
        return res.status(400).json({
            error: "ID do cuidador, Formação e a declaração de aptidão são campos obrigatórios.",
        });
    }

    // Usando a tabela que você mencionou
    const nomeTabela = "cuidador";

    try {
        // 3. Execução da query de ATUALIZAÇÃO no MySQL
        // Atualizamos os campos 'formacao', 'registro_profissional' e definimos o 'status_validacao' como 'Pendente'.
        // Assumimos que 'cuidador_id' corresponde à coluna 'id' da tabela 'cuidador'.
        const [result] = await pool.execute(
            `UPDATE ${nomeTabela} SET 
                    formacao = ?, 
                    registro_profissional = ?, 
                    status_validacao = 'Pendente' 
                WHERE id = ?`,
            [formacao, registro_profissional, cuidador_id]
        );

        // Verifica se o registro foi realmente atualizado
        if (result.affectedRows === 0) {
            return res.status(404).json({ error: `Cuidador com ID ${cuidador_id} não encontrado ou já cadastrado.` });
        }

        // Resposta de sucesso (200 OK para atualização)
        res.status(200).json({
            message: "Informações profissionais atualizadas com sucesso e enviadas para validação.",
            cuidador_id: cuidador_id,
        });
    } catch (error) {
        console.error("Erro ao atualizar dados profissionais:", error);
        // Em caso de erro de banco de dados ou outro erro interno
        res.status(500).json({ error: "Erro interno do servidor ao salvar dados profissionais." });
    }
});

app.post("/api/cuidador/login", async (req, res) => {
    const { identificador, senha } = req.body;
    const nomeTabela = "cuidador"; // Usando a sua tabela 'cuidador'

    if (!identificador || !senha) {
        return res.status(400).json({ error: "Email/Telefone e senha são obrigatórios." });
    }

    try {
        // 1. Busca o usuário por email OU telefone
        // Note que o campo no SQL é 'senha', conforme seu schema de texto puro
        const [rows] = await pool.execute(`SELECT id, nome, senha FROM ${nomeTabela} WHERE email = ? OR telefone = ?`, [
            identificador,
            identificador,
        ]);

        // 2. Verifica se o usuário foi encontrado
        if (rows.length === 0) {
            return res.status(401).json({ error: "Credenciais inválidas." });
        }

        const cuidador = rows[0];

        // 3. Compara a senha fornecida com a senha salva (Texto Puro - INSEGURO)
        const senhaValida = senha === cuidador.senha;

        if (!senhaValida) {
            return res.status(401).json({ error: "Credenciais inválidas." });
        }

        // 4. Sucesso
        res.status(200).json({
            message: "Login bem-sucedido!",
            cuidador_id: cuidador.id,
            nome: cuidador.nome,
        });
    } catch (error) {
        console.error("Erro no login do cuidador:", error);
        res.status(500).json({ error: "Erro interno do servidor durante o login." });
    }
});

app.get("/api/cuidador/perfil", async (req, res) => {
    const id = 1;

    const query = `
            SELECT 
                nome, 
                email, 
                telefone, 
                endereco, 
                data_nascimento, 
                genero
            FROM 
                cuidador 
            WHERE 
                id = 1; 
        `;

    const nomeTabela = "cuidador";

    try {
        const [results] = await pool.execute(query, [id]);

        if (results.length === 0) {
            // Não encontrou o ID 1
            return res.status(404).json({ error: "Cuidador de teste (ID 1) não encontrado no banco de dados." });
        }

        const dadosCuidador = results[0];

        let dataNascimentoFormatada = null;
        if (dadosCuidador.data_nascimento) {
            dataNascimentoFormatada = new Date(dadosCuidador.data_nascimento).toISOString().split("T")[0];
        }

        res.status(200).json({
            nome: dadosCuidador.nome,
            email: dadosCuidador.email,
            numero: dadosCuidador.telefone,
            endereco: dadosCuidador.endereco,
            data_nascimento: dataNascimentoFormatada,
            genero: dadosCuidador.genero,
            info_fisicas: "Informações físicas não especificadas.",
            foto_url: "assets/placeholder.png",
        });
    } catch (error) {
        console.error("Erro ao buscar perfil no BD:", error);
        res.status(500).json({ error: "Erro interno do servidor ao carregar dados do perfil." });
    }
});

app.get("/api/paciente/perfil", async (req, res) => {
    const id = 1; // ID do paciente

    const query = `
        SELECT 
            nome, 
            email,
            idade,
            peso,
            tipo_sanguineo,
            comorbidade,
            data_registro
        FROM 
            pacientes
        WHERE 
            id = ?; 
    `;

    try {
        const [results] = await pool.execute(query, [id]);

        if (results.length === 0) {
            return res.status(404).json({ error: "Paciente de teste (ID 1) não encontrado no banco de dados." });
        }

        const dadosPaciente = results[0];

        res.status(200).json({
            nome: dadosPaciente.nome,
            numero: dadosPaciente.email, // Usando email como "numero" temporariamente
            data_nascimento: "Não informada", // Não temos data_nascimento na tabela
            endereco: "Não informado", // Não temos endereço na tabela
            info_fisicas: dadosPaciente.tipo_sanguineo || "Não informado",
            idade: dadosPaciente.idade,
            peso: dadosPaciente.peso,
            comorbidade: dadosPaciente.comorbidade,
            email: dadosPaciente.email,
            foto_url: "assets/placeholder.png",
        });
    } catch (error) {
        console.error("Erro ao buscar perfil do paciente no BD:", error);
        res.status(500).json({ error: "Erro interno do servidor ao carregar dados do perfil." });
    }
});

// --- ROTA GET: /api/cuidador/SelecionarPaciente/:cuidadorId ---
// Exemplo de rota no Node.js/Express
app.get("/api/pacientes/cuidador/:cuidadorId", async (req, res) => {
    try {
        const { cuidadorId } = req.params;

        const [pacientes] = await connection.execute(
            "SELECT id, nome, idade, peso, tipo_sanguineo, comorbidade, cuidador_id FROM pacientes WHERE cuidador_id = ?",
            [cuidadorId]
        );

        res.json(pacientes);
    } catch (error) {
        res.status(500).json({ error: "Erro ao buscar pacientes" });
    }
});

app.post("/api/cuidador/MedicamentoPaciente", async (req, res) => {
    // 1. Dados vêm do corpo da requisição JSON
    const { cuidador_id, paciente_id, medicamento_nome, dosagem, data_hora } = req.body;

    // 2. Validação dos campos obrigatórios
    if (!cuidador_id || !paciente_id || !medicamento_nome || !dosagem || !data_hora) {
        return res.status(400).json({
            error: "Todos os campos são obrigatórios: cuidador_id, paciente_id, medicamento_nome, dosagem, data_hora",
        });
    }

    // 3. Validação da data/hora
    const dataHoraAgendamento = new Date(data_hora);
    if (isNaN(dataHoraAgendamento.getTime())) {
        return res.status(400).json({
            error: "Data/hora inválida. Use o formato ISO: YYYY-MM-DDTHH:MM:SS",
        });
    }

    // 4. Verifica se não é uma data passada
    if (dataHoraAgendamento < new Date()) {
        return res.status(400).json({
            error: "Não é possível agendar medicamentos para datas/horas passadas",
        });
    }

    const nomeTabela = "agendamentos_medicamentos";

    try {
        // 5. Executa a inserção no banco de dados
        const [result] = await pool.execute(
            `INSERT INTO ${nomeTabela} 
                (cuidador_id, paciente_id, medicamento_nome, dosagem, data_hora, status) 
                VALUES (?, ?, ?, ?, ?, 'pendente')`,
            [cuidador_id, paciente_id, medicamento_nome, dosagem, dataHoraAgendamento]
        );

        // 6. Resposta de sucesso
        res.status(201).json({
            id: result.insertId,
            message: "Medicamento agendado com sucesso!",
            agendamento: {
                id: result.insertId,
                cuidador_id: cuidador_id,
                paciente_id: paciente_id,
                medicamento_nome: medicamento_nome,
                dosagem: dosagem,
                data_hora: data_hora,
                status: "pendente",
            },
        });
    } catch (error) {
        console.error("Erro ao agendar medicamento:", error);

        // 7. Tratamento de erros específicos
        if (error.code === "ER_NO_REFERENCED_ROW") {
            return res.status(400).json({
                error: "Cuidador ou paciente não encontrado. Verifique os IDs.",
            });
        }

        res.status(500).json({
            error: "Erro interno do servidor ao agendar medicamento.",
        });
    }
});

// ... (seu código existente do express, cors, mysql, etc.)

// --- NOVO ENDPOINT PARA BUSCAR TODOS OS PACIENTES (GET) ---
app.post("/api/cuidador/PacienteConsulta1", async (req, res) => {
    const { cuidador_id, paciente_id, especialidade, medico_nome, hora_consulta } = req.body;

    // Validação dos campos obrigatórios
    if (!cuidador_id || !paciente_id || !especialidade || !medico_nome || !hora_consulta) {
        return res.status(400).json({
            error: "Campos obrigatórios: cuidador_id, paciente_id, especialidade, medico_nome, hora_consulta",
        });
    }

    try {
        // Validação da data/hora
        const dataHoraAgendamento = new Date(hora_consulta);
        if (isNaN(dataHoraAgendamento.getTime())) {
            return res.status(400).json({
                error: "Data/hora inválida. Use o formato ISO: YYYY-MM-DDTHH:MM:SS",
            });
        }

        // Verifica se não é uma data passada
        if (dataHoraAgendamento < new Date()) {
            return res.status(400).json({
                error: "Não é possível agendar consultas para datas/horas passadas",
            });
        }

        const nomeTabela = "consultas";

        // Executa a inserção no banco de dados
        const [result] = await pool.execute(
            `INSERT INTO ${nomeTabela} 
            (cuidador_id, paciente_id, especialidade, medico_nome, hora_consulta, status) 
            VALUES (?, ?, ?, ?, ?, 'pendente')`,
            [cuidador_id, paciente_id, especialidade, medico_nome, hora_consulta]
        );

        // Resposta de sucesso
        res.status(201).json({
            id: result.insertId,
            message: "Consulta agendada com sucesso!",
            agendamento: {
                id: result.insertId,
                cuidador_id: cuidador_id,
                paciente_id: paciente_id,
                especialidade: especialidade,
                medico_nome: medico_nome,
                hora_consulta: hora_consulta,
                status: "pendente",
            },
        });
    } catch (error) {
        console.error("Erro ao agendar consulta:", error);

        // Tratamento de erros específicos
        if (error.code === "ER_NO_REFERENCED_ROW") {
            return res.status(400).json({
                error: "Cuidador ou paciente não encontrado. Verifique os IDs.",
            });
        }

        res.status(500).json({
            error: "Erro interno do servidor ao agendar consulta.",
        });
    }
});

app.get("/api/cuidador/SelecionarPacienteMedicamento", async (req, res) => {
    try {
        console.log(`🔍 Buscando todos os pacientes`);

        const query = `
            SELECT 
              id,
              nome,
              idade,
              peso,
              tipo_sanguineo as tipoSanguineo,
              comorbidade,
              cuidador_id as cuidadorId,
              data_registro as dataRegistro
            FROM pacientes 
            ORDER BY nome
        `;

        // CORREÇÃO: Removido 'const' antes do await pool.execute
        const [results] = await pool.execute(query);

        console.log(`✅ ${results.length} pacientes encontrados`);

        res.json({
            success: true,
            data: results,
            count: results.length,
        });
    } catch (err) {
        console.error("❌ Erro na consulta:", err);
        return res.status(500).json({
            success: false,
            error: "Erro interno do servidor",
            details: err.message,
        });
    }
});

app.get("/api/cuidador/SelecionarPacienteConsulta", async (req, res) => {
    try {
        console.log(`🔍 Buscando todos os pacientes`);

        const query = `
            SELECT 
              id,
              nome,
              idade,
              peso,
              tipo_sanguineo as tipoSanguineo,
              comorbidade,
              cuidador_id as cuidadorId,
              data_registro as dataRegistro
            FROM pacientes 
            ORDER BY nome
        `;

        // CORREÇÃO: Removido 'const' antes do await pool.execute
        const [results] = await pool.execute(query);

        console.log(`✅ ${results.length} pacientes encontrados`);

        res.json({
            success: true,
            data: results,
            count: results.length,
        });
    } catch (err) {
        console.error("❌ Erro na consulta:", err);
        return res.status(500).json({
            success: false,
            error: "Erro interno do servidor",
            details: err.message,
        });
    }
});

app.post("/api/medicamentos", async (req, res) => {
    try {
        const { patient_name, medication_name, dosage, date, time, cuidador_id } = req.body;

        console.log(`💊 Salvando medicamento para: ${patient_name}`);
        console.log(`Medicamento: ${medication_name}, Dosagem: ${dosage}`);
        console.log(`Data: ${date}, Hora: ${time}, Cuidador ID: ${cuidador_id}`);

        if (!patient_name || !medication_name || !dosage || !date || !time || !cuidador_id) {
            return res.status(400).json({
                success: false,
                error: "Todos os campos são obrigatórios, incluindo cuidador_id",
            });
        }

        // Buscar o ID do paciente pelo nome
        const [patientResults] = await pool.execute("SELECT id, cuidador_id FROM pacientes WHERE nome = ?", [
            patient_name,
        ]);

        if (patientResults.length === 0) {
            return res.status(404).json({
                success: false,
                error: "Paciente não encontrado",
            });
        }

        const paciente_id = patientResults[0].id;
        const pacienteCuidadorId = patientResults[0].cuidador_id;

        // Verificar se o cuidador_id fornecido corresponde ao do paciente
        if (pacienteCuidadorId && pacienteCuidadorId !== parseInt(cuidador_id)) {
            return res.status(403).json({
                success: false,
                error: "Cuidador não autorizado para este paciente",
            });
        }

        // Formatar a data e hora para DATETIME (YYYY-MM-DD HH:MM:SS)
        const formattedDate = new Date(date).toISOString().split("T")[0];
        const dataHora = `${formattedDate} ${time}:00`;

        // CORREÇÃO: Incluir cuidador_id na query
        const query = `
            INSERT INTO agendamentos_medicamentos 
            (cuidador_id, paciente_id, medicamento_nome, dosagem, data_hora, status) 
            VALUES (?, ?, ?, ?, ?, ?)
        `;

        const [result] = await pool.execute(query, [
            cuidador_id, // ← CORREÇÃO: Adicionar cuidador_id
            paciente_id,
            medication_name,
            dosage,
            dataHora,
            "pendente",
        ]);

        console.log(`✅ Medicamento salvo com ID: ${result.insertId}`);

        res.status(201).json({
            success: true,
            message: "Medicamento agendado com sucesso",
            data: {
                id: result.insertId,
                cuidador_id: cuidador_id,
                patient_name,
                medication_name,
                dosage,
                data_hora: dataHora,
                status: "pendente",
            },
        });
    } catch (err) {
        console.error("❌ Erro ao salvar medicamento:", err);
        return res.status(500).json({
            success: false,
            error: "Erro interno do servidor",
            details: err.message,
        });
    }
});

app.post("/api/cuidador/ConsultasPaciente", async (req, res) => {
    // 1. Dados vêm do corpo da requisição JSON
    const {
        cuidador_id,
        paciente_id,
        especialidade,
        medico_nome,
        crm_medico,
        data_consulta,
        hora_consulta,
        local_consulta,
        endereco_consulta,
        tipo_consulta,
    } = req.body;

    // 2. Validação dos campos obrigatórios
    if (!cuidador_id || !paciente_id || !especialidade || !medico_nome || !data_consulta || !hora_consulta) {
        return res.status(400).json({
            error: "Campos obrigatórios: cuidador_id, paciente_id, especialidade, medico_nome, data_consulta, hora_consulta",
        });
    }

    // 3. Validação da data
    const dataConsulta = new Date(data_consulta);
    if (isNaN(dataConsulta.getTime())) {
        return res.status(400).json({
            error: "Data inválida. Use o formato: YYYY-MM-DD",
        });
    }

    // 4. Verifica se não é uma data passada
    const hoje = new Date();
    hoje.setHours(0, 0, 0, 0);
    if (dataConsulta < hoje) {
        return res.status(400).json({
            error: "Não é possível agendar consultas para datas passadas",
        });
    }

    // 5. Validação do tipo_consulta (deve ser um dos valores do ENUM)
    const tiposValidos = ["presencial", "telemedicina", "domiciliar"];
    const tipoConsultaFinal = tipo_consulta || "presencial";

    if (!tiposValidos.includes(tipoConsultaFinal)) {
        return res.status(400).json({
            error: `Tipo de consulta inválido. Use um dos seguintes: ${tiposValidos.join(", ")}`,
        });
    }

    try {
        // 6. Executa a inserção no banco de dados - CORRIGIDO: removido o campo 'status'
        const [result] = await pool.execute(
            `INSERT INTO consultas 
            (cuidador_id, paciente_id, tipo_consulta, especialidade, medico_nome, crm_medico, 
             data_consulta, hora_consulta, local_consulta, endereco_consulta) 
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
            [
                cuidador_id,
                paciente_id,
                tipoConsultaFinal,
                especialidade,
                medico_nome,
                crm_medico || null,
                data_consulta,
                hora_consulta,
                local_consulta || null,
                endereco_consulta || null,
            ]
        );

        // 7. Resposta de sucesso
        res.status(201).json({
            id: result.insertId,
            message: "Consulta agendada com sucesso!",
            consulta: {
                id: result.insertId,
                cuidador_id: cuidador_id,
                paciente_id: paciente_id,
                tipo_consulta: tipoConsultaFinal,
                especialidade: especialidade,
                medico_nome: medico_nome,
                crm_medico: crm_medico,
                data_consulta: data_consulta,
                hora_consulta: hora_consulta,
                local_consulta: local_consulta,
                endereco_consulta: endereco_consulta,
            },
        });
    } catch (error) {
        console.error("Erro ao agendar consulta:", error);

        // 8. Tratamento de erros específicos
        if (error.code === "ER_NO_REFERENCED_ROW") {
            return res.status(400).json({
                error: "Cuidador ou paciente não encontrado. Verifique os IDs.",
            });
        }

        // Erro de chave estrangeira - tabela cuidador não existe
        if (error.code === "ER_NO_SUCH_TABLE") {
            return res.status(500).json({
                error: "Erro de configuração do banco de dados. Tabela referenciada não existe.",
            });
        }

        res.status(500).json({
            error: "Erro interno do servidor ao agendar consulta.",
            details: error.message,
        });
    }
});

app.post("/api/cuidador/PacienteTarefa", async (req, res) => {
    const { cuidador_id, paciente_id, descricao, motivacao, data_tarefa } = req.body;

    // Validação dos campos obrigatórios
    if (!cuidador_id || !paciente_id || !descricao || !motivacao || !data_tarefa) {
        return res.status(400).json({
            error: "Campos obrigatórios: cuidador_id, paciente_id, descricao, motivacao, data_tarefa",
        });
    }

    try {
        // Validação da data/hora
        const dataHoraAgendamento = new Date(data_tarefa);
        if (isNaN(dataHoraAgendamento.getTime())) {
            return res.status(400).json({
                error: "Data/hora inválida. Use o formato ISO: YYYY-MM-DDTHH:MM:SS",
            });
        }

        // Verifica se não é uma data passada
        if (dataHoraAgendamento < new Date()) {
            return res.status(400).json({
                error: "Não é possível agendar consultas para datas/horas passadas",
            });
        }

        const nomeTabela = "tarefas";

        // Executa a inserção no banco de dados
        const [result] = await pool.execute(
            `INSERT INTO ${nomeTabela} 
            (cuidador_id, paciente_id, descricao, motivacao, data_tarefa) 
            VALUES (?, ?, ?, ?, ?)`,
            [cuidador_id, paciente_id, descricao, motivacao, data_tarefa]
        );

        // Resposta de sucesso
        res.status(201).json({
            id: result.insertId,
            message: "Tarefa agendada com sucesso!",
            agendamento: {
                id: result.insertId,
                cuidador_id: cuidador_id,
                paciente_id: paciente_id,
                descricao: descricao,
                motivacao: motivacao,
                data_tarefa: data_tarefa,
            },
        });
    } catch (error) {
        console.error("Erro ao agendar tarefa:", error);

        // Tratamento de erros específicos
        if (error.code === "ER_NO_REFERENCED_ROW") {
            return res.status(400).json({
                error: "Cuidador ou paciente não encontrado. Verifique os IDs.",
            });
        }

        res.status(500).json({
            error: "Erro interno do servidor ao agendar consulta.",
        });
    }
});

app.get("/api/cuidador/SelecionarPacienteTarefa", async (req, res) => {
    try {
        console.log(`🔍 Buscando todos os pacientes`);

        const query = `
            SELECT 
              id,
              nome,
              idade,
              peso,
              tipo_sanguineo as tipoSanguineo,
              comorbidade,
              cuidador_id as cuidadorId,
              data_registro as dataRegistro
            FROM pacientes 
            ORDER BY nome
        `;

        // CORREÇÃO: Removido 'const' antes do await pool.execute
        const [results] = await pool.execute(query);

        console.log(`✅ ${results.length} pacientes encontrados`);

        res.json({
            success: true,
            data: results,
            count: results.length,
        });
    } catch (err) {
        console.error("❌ Erro na consulta:", err);
        return res.status(500).json({
            success: false,
            error: "Erro interno do servidor",
            details: err.message,
        });
    }
});

// Função auxiliar para calcular status
function calcularStatus(dataHora, statusAtual) {
    // Se já está marcado como feito ou cancelado, mantém o status
    if (statusAtual === "feita" || statusAtual === "cancelada") {
        return statusAtual;
    }

    const agora = new Date();
    const dataEvento = new Date(dataHora);

    // Se a data/hora já passou e ainda está pendente → atrasada
    if (dataEvento < agora && statusAtual === "pendente") {
        return "atrasada";
    }

    return statusAtual;
}

app.get("/api/cuidador/PacienteComConsulta", async (req, res) => {
    try {
        console.log(`🔍 Buscando todos os pacientes com consultas`);

        const query = `
            SELECT 
                p.id,
                p.nome,
                p.idade,
                p.peso,
                p.tipo_sanguineo,
                p.comorbidade,
                p.cuidador_id,
                c.id as consulta_id,
                c.tipo_consulta,
                c.especialidade,
                c.medico_nome,
                c.crm_medico,
                c.hora_consulta,
                c.local_consulta,
                c.endereco_consulta,
                c.status as status_consulta
            FROM pacientes p
            LEFT JOIN consultas c ON p.id = c.paciente_id
            ORDER BY p.nome, c.hora_consulta DESC
        `;

        const [results] = await pool.execute(query);

        console.log(`✅ ${results.length} registros encontrados`);

        // Agrupar pacientes com suas consultas
        const pacientesComConsultas = results.reduce((acc, row) => {
            const pacienteId = row.id;

            if (!acc[pacienteId]) {
                acc[pacienteId] = {
                    id: row.id,
                    nome: row.nome,
                    idade: row.idade,
                    peso: row.peso,
                    tipo_sanguineo: row.tipo_sanguineo,
                    comorbidade: row.comorbidade,
                    cuidador_id: row.cuidador_id,
                    consultas: [],
                };
            }

            if (row.consulta_id) {
                const statusCalculado = calcularStatus(row.hora_consulta, row.status_consulta);

                acc[pacienteId].consultas.push({
                    id: row.consulta_id,
                    tipo_consulta: row.tipo_consulta,
                    especialidade: row.especialidade,
                    medico_nome: row.medico_nome,
                    crm_medico: row.crm_medico,
                    hora_consulta: row.hora_consulta,
                    local_consulta: row.local_consulta,
                    endereco_consulta: row.endereco_consulta,
                    status: statusCalculado,
                    status_original: row.status_consulta, // mantém o original do banco
                });
            }

            return acc;
        }, {});

        const pacientesArray = Object.values(pacientesComConsultas);

        console.log(`📊 ${pacientesArray.length} pacientes processados`);

        res.json({
            success: true,
            data: pacientesArray,
            count: pacientesArray.length,
            totalConsultas: results.filter((row) => row.consulta_id).length,
        });
    } catch (err) {
        console.error("❌ Erro na consulta:", err);
        return res.status(500).json({
            success: false,
            error: "Erro interno do servidor",
            details: err.message,
        });
    }
});

app.get("/api/cuidador/PacienteComMedicamentos", async (req, res) => {
    try {
        console.log(`🔍 Buscando todos os pacientes com medicamentos`);

        const query = `
            SELECT 
                p.id,
                p.nome,
                p.idade,
                p.peso,
                p.tipo_sanguineo,
                p.comorbidade,
                p.cuidador_id,
                am.id as medicamento_id,
                am.medicamento_nome,
                am.dosagem,
                am.data_hora,
                am.status as status_medicamento,
                am.created_at,
                am.updated_at
            FROM pacientes p
            LEFT JOIN agendamentos_medicamentos am ON p.id = am.paciente_id
            ORDER BY p.nome, am.data_hora DESC
        `;

        const [results] = await pool.execute(query);

        console.log(`✅ ${results.length} registros encontrados`);

        // Agrupar pacientes com seus medicamentos
        const pacientesComMedicamentos = results.reduce((acc, row) => {
            const pacienteId = row.id;

            if (!acc[pacienteId]) {
                acc[pacienteId] = {
                    id: row.id,
                    nome: row.nome,
                    idade: row.idade,
                    peso: row.peso,
                    tipo_sanguineo: row.tipo_sanguineo,
                    comorbidade: row.comorbidade,
                    cuidador_id: row.cuidador_id,
                    medicamentos: [],
                };
            }

            if (row.medicamento_id) {
                const statusCalculado = calcularStatus(row.data_hora, row.status_medicamento);

                acc[pacienteId].medicamentos.push({
                    id: row.medicamento_id,
                    medicamento_nome: row.medicamento_nome,
                    dosagem: row.dosagem,
                    data_hora: row.data_hora,
                    status: statusCalculado,
                    status_original: row.status_medicamento, // mantém o original do banco
                    created_at: row.created_at,
                    updated_at: row.updated_at,
                });
            }

            return acc;
        }, {});

        const pacientesArray = Object.values(pacientesComMedicamentos);

        console.log(`📊 ${pacientesArray.length} pacientes processados`);

        res.json({
            success: true,
            data: pacientesArray,
            count: pacientesArray.length,
            totalMedicamentos: results.filter((row) => row.medicamento_id).length,
        });
    } catch (err) {
        console.error("❌ Erro na consulta:", err);
        return res.status(500).json({
            success: false,
            error: "Erro interno do servidor",
            details: err.message,
        });
    }
});

app.get("/api/cuidador/PacienteComTarefas", async (req, res) => {
    try {
        console.log(`🔍 Buscando todos os pacientes com tarefas`);

        const query = `
            SELECT 
                p.id,
                p.nome,
                p.idade,
                p.peso,
                p.tipo_sanguineo,
                p.comorbidade,
                p.cuidador_id,
                t.id as tarefa_id,
                t.motivacao,
                t.descricao,
                t.data_tarefa,
                t.status as status_tarefa
            FROM pacientes p
            LEFT JOIN tarefas t ON p.id = t.paciente_id
            ORDER BY p.nome, t.data_tarefa DESC
        `;

        const [results] = await pool.execute(query);

        console.log(`✅ ${results.length} registros encontrados`);

        const pacientesComTarefas = results.reduce((acc, row) => {
            const pacienteId = row.id;

            if (!acc[pacienteId]) {
                acc[pacienteId] = {
                    id: row.id,
                    nome: row.nome,
                    idade: row.idade,
                    peso: row.peso,
                    tipo_sanguineo: row.tipo_sanguineo,
                    comorbidade: row.comorbidade,
                    cuidador_id: row.cuidador_id,
                    tarefas: [],
                };
            }

            if (row.tarefa_id) {
                const statusCalculado = calcularStatus(row.data_tarefa, row.status_tarefa);

                acc[pacienteId].tarefas.push({
                    id: row.tarefa_id,
                    motivacao: row.motivacao,
                    descricao: row.descricao,
                    data_tarefa: row.data_tarefa,
                    status: statusCalculado,
                    status_original: row.status_tarefa, // mantém o original do banco
                });
            }

            return acc;
        }, {});

        const pacientesArray = Object.values(pacientesComTarefas);

        console.log(`📊 ${pacientesArray.length} pacientes processados`);

        res.json({
            success: true,
            data: pacientesArray,
            count: pacientesArray.length,
            totalTarefas: results.filter((row) => row.tarefa_id).length,
        });
    } catch (err) {
        console.error("❌ Erro na consulta:", err);
        return res.status(500).json({
            success: false,
            error: "Erro interno do servidor",
            details: err.message,
        });
    }
});

// Atualizar status de consulta
app.put("/api/consulta/:id/status", async (req, res) => {
    try {
        const { id } = req.params;
        const { status } = req.body;

        if (!["pendente", "atrasada", "feita", "cancelada"].includes(status)) {
            return res.status(400).json({
                success: false,
                error: "Status inválido",
            });
        }

        const query = "UPDATE consultas SET status = ? WHERE id = ?";
        const [result] = await pool.execute(query, [status, id]);

        if (result.affectedRows === 0) {
            return res.status(404).json({
                success: false,
                error: "Consulta não encontrada",
            });
        }

        res.json({
            success: true,
            message: "Status atualizado com sucesso",
        });
    } catch (err) {
        console.error("❌ Erro ao atualizar status:", err);
        return res.status(500).json({
            success: false,
            error: "Erro interno do servidor",
        });
    }
});

// Atualizar status de medicamento
app.put("/api/medicamento/:id/status", async (req, res) => {
    try {
        const { id } = req.params;
        const { status } = req.body;

        if (!["pendente", "atrasada", "feita", "cancelada"].includes(status)) {
            return res.status(400).json({
                success: false,
                error: "Status inválido",
            });
        }

        const query = "UPDATE agendamentos_medicamentos SET status = ? WHERE id = ?";
        const [result] = await pool.execute(query, [status, id]);

        if (result.affectedRows === 0) {
            return res.status(404).json({
                success: false,
                error: "Medicamento não encontrado",
            });
        }

        res.json({
            success: true,
            message: "Status atualizado com sucesso",
        });
    } catch (err) {
        console.error("❌ Erro ao atualizar status:", err);
        return res.status(500).json({
            success: false,
            error: "Erro interno do servidor",
        });
    }
});

// Job para atualizar status automaticamente (executar a cada hora)
async function atualizarStatusAutomaticamente() {
    try {
        console.log("🔄 Atualizando status automaticamente...");

        // Atualizar consultas atrasadas
        await pool.execute(
            `UPDATE consultas 
             SET status = 'atrasada' 
             WHERE status = 'pendente' 
             AND hora_consulta < NOW()`
        );

        // Atualizar medicamentos atrasados
        await pool.execute(
            `UPDATE agendamentos_medicamentos 
             SET status = 'atrasada' 
             WHERE status = 'pendente' 
             AND data_hora < NOW()`
        );

        // Atualizar tarefas atrasadas
        await pool.execute(
            `UPDATE tarefas 
             SET status = 'atrasada' 
             WHERE status = 'pendente' 
             AND data_tarefa < NOW()`
        );

        console.log("✅ Status atualizados automaticamente");
    } catch (err) {
        console.error("❌ Erro na atualização automática:", err);
    }
}

// Executar a cada hora (opcional)
setInterval(atualizarStatusAutomaticamente, 60 * 60 * 1000);

app.post("/api/paciente/login", async (req, res) => {
    const { identificador, senha } = req.body;
    const nomeTabela = "pacientes";

    if (!identificador || !senha) {
        return res.status(400).json({ error: "Email/Telefone e senha são obrigatórios." });
    }

    try {
        // 1. Busca o usuário por email OU telefone
        const [rows] = await pool.execute(
            `SELECT email, senha FROM ${nomeTabela} WHERE email = ?`,
            [identificador] // Agora são 2 parâmetros para 2 placeholders
        );

        // 2. Verifica se o usuário foi encontrado
        if (rows.length === 0) {
            return res.status(401).json({ error: "Credenciais inválidas." });
        }

        const paciente = rows[0];

        // 3. Verifica a senha (TEXTO PURO - considere usar bcrypt depois)
        const senhaValida = senha === paciente.senha;
        if (!senhaValida) {
            return res.status(401).json({ error: "Credenciais inválidas." });
        }

        // 4. Login bem-sucedido
        res.status(200).json({
            message: "Login bem-sucedido!",
            paciente_id: paciente.id,
            nome: paciente.nome, // Agora o campo nome está disponível
        });
    } catch (error) {
        console.error("Erro no login do paciente:", error);
        res.status(500).json({ error: "Erro interno do servidor durante o login." });
    }
});

app.put("/api/tarefa/:id/status", async (req, res) => {
    try {
        const { id } = req.params;
        const { status } = req.body;

        // Validar status permitidos
        const statusPermitidos = ["pendente", "atrasada", "feita", "cancelada"];
        if (!statusPermitidos.includes(status)) {
            return res.status(400).json({
                success: false,
                error: `Status inválido. Use: ${statusPermitidos.join(", ")}`,
            });
        }

        // Buscar tarefa atual com mais detalhes
        const [tarefas] = await pool.execute(
            `SELECT t.*, p.nome as paciente_nome 
             FROM tarefas t 
             LEFT JOIN pacientes p ON t.paciente_id = p.id 
             WHERE t.id = ?`,
            [id]
        );

        if (tarefas.length === 0) {
            return res.status(404).json({
                success: false,
                error: "Tarefa não encontrada",
            });
        }

        const tarefa = tarefas[0];

        // Atualizar status da tarefa
        const query = "UPDATE tarefas SET status = ? WHERE id = ?";
        const [result] = await pool.execute(query, [status, id]);

        if (result.affectedRows === 0) {
            return res.status(404).json({
                success: false,
                error: "Tarefa não encontrada",
            });
        }

        // Buscar tarefa atualizada para retornar
        const [tarefaAtualizada] = await pool.execute(
            `SELECT t.*, p.nome as paciente_nome 
             FROM tarefas t 
             LEFT JOIN pacientes p ON t.paciente_id = p.id 
             WHERE t.id = ?`,
            [id]
        );

        console.log(`✅ Status da tarefa ${id} (${tarefa.motivacao}) alterado para: ${status}`);

        res.json({
            success: true,
            message: "Status da tarefa atualizado com sucesso",
            data: tarefaAtualizada[0],
        });
    } catch (err) {
        console.error("❌ Erro ao atualizar status da tarefa:", err);
        return res.status(500).json({
            success: false,
            error: "Erro interno do servidor",
        });
    }
});

app.get("/api/cuidador/ExibirPacientes", async (req, res) => {
    const query = `
        SELECT 
            id,
            nome,
            idade,
            peso,
            tipo_sanguineo,
            comorbidade,
            cuidador_id,
            email,
            data_registro
        FROM pacientes
    `;

    try {
        const [results] = await pool.execute(query);

        if (results.length === 0) {
            return res.json({
                success: true,
                data: [],
                total: 0,
                message: "Nenhum paciente encontrado",
            });
        }

        // Formatar os dados para a resposta
        const pacientes = results.map((paciente) => ({
            id: paciente.id,
            nome: paciente.nome,
            idade: `${paciente.idade} anos`,
            peso: paciente.peso ? `${paciente.peso} kg` : "Não informado",
            tipo_sanguineo: paciente.tipo_sanguineo || "Não informado",
            comorbidade: paciente.comorbidade || "Nenhuma",
            cuidador_id: paciente.cuidador_id,
            email: paciente.email,
            data_registro: paciente.data_registro,
            imagePath: "assets/default_avatar.png", // Path padrão para imagem
        }));

        res.json({
            success: true,
            data: pacientes,
            total: pacientes.length,
        });
    } catch (error) {
        console.error("Erro ao buscar pacientes:", error);
        res.status(500).json({
            success: false,
            error: "Erro interno do servidor",
            message: error.message,
        });
    }
});

app.get("/api/cuidador/PacienteComAgendaCompleta", async (req, res) => {
    try {
        console.log(`🔍 Buscando todos os pacientes com agenda completa`);

        const query = `
            SELECT 
                p.id,
                p.nome,
                p.idade,
                p.peso,
                p.tipo_sanguineo,
                p.comorbidade,
                p.cuidador_id,
                
                -- Consultas
                c.id as consulta_id,
                c.tipo_consulta,
                c.especialidade,
                c.medico_nome,
                c.crm_medico,
                c.hora_consulta,
                c.local_consulta,
                c.endereco_consulta,
                c.status as status_consulta,
                
                -- Medicamentos
                am.id as medicamento_id,
                am.medicamento_nome,
                am.dosagem,
                am.data_hora,
                am.status as status_medicamento,
                am.created_at,
                am.updated_at,
                
                -- Tarefas
                t.id as tarefa_id,
                t.motivacao,
                t.descricao,
                t.data_tarefa
                
            FROM pacientes p
            LEFT JOIN consultas c ON p.id = c.paciente_id
            LEFT JOIN agendamentos_medicamentos am ON p.id = am.paciente_id
            LEFT JOIN tarefas t ON p.id = t.paciente_id
            ORDER BY p.nome, c.hora_consulta DESC, am.data_hora DESC, t.data_tarefa DESC
        `;

        const [results] = await pool.execute(query);

        console.log(`✅ ${results.length} registros encontrados`);

        // Agrupar pacientes com todos os dados
        const pacientesComAgenda = results.reduce((acc, row) => {
            const pacienteId = row.id;

            if (!acc[pacienteId]) {
                acc[pacienteId] = {
                    id: row.id,
                    nome: row.nome,
                    idade: row.idade,
                    peso: row.peso,
                    tipo_sanguineo: row.tipo_sanguineo,
                    comorbidade: row.comorbidade,
                    cuidador_id: row.cuidador_id,
                    consultas: [],
                    medicamentos: [],
                    tarefas: [],
                };
            }

            // Adicionar consulta se existir e não estiver duplicada
            if (row.consulta_id && !acc[pacienteId].consultas.some((c) => c.id === row.consulta_id)) {
                acc[pacienteId].consultas.push({
                    id: row.consulta_id,
                    tipo_consulta: row.tipo_consulta,
                    especialidade: row.especialidade,
                    medico_nome: row.medico_nome,
                    crm_medico: row.crm_medico,
                    hora_consulta: row.hora_consulta,
                    local_consulta: row.local_consulta,
                    endereco_consulta: row.endereco_consulta,
                    status: row.status_consulta,
                });
            }

            // Adicionar medicamento se existir e não estiver duplicado
            if (row.medicamento_id && !acc[pacienteId].medicamentos.some((m) => m.id === row.medicamento_id)) {
                acc[pacienteId].medicamentos.push({
                    id: row.medicamento_id,
                    medicamento_nome: row.medicamento_nome,
                    dosagem: row.dosagem,
                    data_hora: row.data_hora,
                    status: row.status_medicamento,
                    created_at: row.created_at,
                    updated_at: row.updated_at,
                });
            }

            // Adicionar tarefa se existir e não estiver duplicada
            if (row.tarefa_id && !acc[pacienteId].tarefas.some((t) => t.id === row.tarefa_id)) {
                acc[pacienteId].tarefas.push({
                    id: row.tarefa_id,
                    motivacao: row.motivacao,
                    descricao: row.descricao,
                    data_tarefa: row.data_tarefa,
                });
            }

            return acc;
        }, {});

        const pacientesArray = Object.values(pacientesComAgenda);

        console.log(`📊 ${pacientesArray.length} pacientes processados`);
        console.log(`🩺 Total consultas: ${pacientesArray.reduce((acc, p) => acc + p.consultas.length, 0)}`);
        console.log(`💊 Total medicamentos: ${pacientesArray.reduce((acc, p) => acc + p.medicamentos.length, 0)}`);
        console.log(`📝 Total tarefas: ${pacientesArray.reduce((acc, p) => acc + p.tarefas.length, 0)}`);

        res.json({
            success: true,
            data: pacientesArray,
            count: pacientesArray.length,
            totalConsultas: pacientesArray.reduce((acc, p) => acc + p.consultas.length, 0),
            totalMedicamentos: pacientesArray.reduce((acc, p) => acc + p.medicamentos.length, 0),
            totalTarefas: pacientesArray.reduce((acc, p) => acc + p.tarefas.length, 0),
        });
    } catch (err) {
        console.error("❌ Erro na consulta:", err);
        return res.status(500).json({
            success: false,
            error: "Erro interno do servidor",
            details: err.message,
        });
    }
});

app.get("/api/cuidador/familiar/meus-dados", async (req, res) => {
    try {
        console.log(`🔍 Buscando dados do familiar`);

        // NOTA: Você precisará implementar a autenticação para saber qual familiar está logado
        // Por enquanto, vou assumir que o ID do familiar está vindo via query parameter
        // Ou você pode usar um sistema de autenticação JWT
        const familiarId = req.query.familiar_id || req.user?.id; // Adapte conforme sua autenticação

        if (!familiarId) {
            return res.status(400).json({
                success: false,
                error: "ID do familiar não fornecido",
            });
        }

        const query = `
            SELECT 
                id,
                nome,
                email,
                telefone,
                endereco,
                data_nascimento,
                genero,
                data_registro
            FROM familiares 
            WHERE id = ?
        `;

        const [results] = await pool.execute(query, [familiarId]);

        if (results.length === 0) {
            return res.status(404).json({
                success: false,
                error: "Familiar não encontrado",
            });
        }

        const familiar = results[0];

        console.log(`✅ Dados do familiar encontrados: ${familiar.nome}`);

        res.json({
            success: true,
            data: familiar,
        });
    } catch (err) {
        console.error("❌ Erro na consulta:", err);
        return res.status(500).json({
            success: false,
            error: "Erro interno do servidor",
            details: err.message,
        });
    }
});

app.get("/api/familiar/perfil", async (req, res) => {
    const id = 1;

    const query = `
        SELECT 
            nome, 
            email, 
            telefone, 
            endereco, 
            data_nascimento, 
            genero
        FROM 
            familiares
        WHERE 
            id = ?; 
    `;

    try {
        const [results] = await pool.execute(query, [id]);

        if (results.length === 0) {
            return res.status(404).json({ error: "Familiar de teste (ID 1) não encontrado no banco de dados." });
        }

        const dadosFamiliares = results[0];

        let dataNascimentoFormatada = null;
        if (dadosFamiliares.data_nascimento) {
            dataNascimentoFormatada = new Date(dadosFamiliares.data_nascimento).toISOString().split("T")[0];
        }

        res.status(200).json({
            nome: dadosFamiliares.nome,
            numero: dadosFamiliares.telefone,
            data_nascimento: dataNascimentoFormatada,
            endereco: dadosFamiliares.endereco,
            info_fisicas: dadosFamiliares.email, // ✅ CORREÇÃO: email vai para info_fisicas
            foto_url: "assets/placeholder.png",
            genero: dadosFamiliares.genero,
        });
    } catch (error) {
        console.error("Erro ao buscar perfil no BD:", error);
        res.status(500).json({ error: "Erro interno do servidor ao carregar dados do perfil." });
    }
});

// Endpoint para alterar senha do cuidador
app.put("/api/cuidador/alterar-senha", async (req, res) => {
    const { email, senhaAtual, novaSenha } = req.body;

    if (!email || !senhaAtual || !novaSenha) {
        return res.status(400).json({
            success: false,
            message: "Email, senha atual e nova senha são obrigatórios",
        });
    }

    let connection;
    try {
        // Obter conexão do pool
        connection = await pool.getConnection();

        // Verificar se o cuidador existe e a senha atual está correta
        const [cuidadores] = await connection.execute("SELECT id, senha FROM cuidador WHERE email = ?", [email]);

        if (cuidadores.length === 0) {
            return res.status(404).json({
                success: false,
                message: "Cuidador não encontrado",
            });
        }

        const cuidador = cuidadores[0];

        // Verificar senha atual
        if (senhaAtual !== cuidador.senha) {
            return res.status(401).json({
                success: false,
                message: "Senha atual incorreta",
            });
        }

        // Atualizar a senha
        await connection.execute("UPDATE cuidador SET senha = ? WHERE email = ?", [novaSenha, email]);

        res.json({
            success: true,
            message: "Senha alterada com sucesso",
        });
    } catch (error) {
        console.error("Erro ao alterar senha:", error);
        res.status(500).json({
            success: false,
            message: "Erro interno do servidor",
        });
    } finally {
        // Liberar a conexão de volta para o pool
        if (connection) connection.release();
    }
});

// Endpoint para alterar senha do cuidador
app.put("/api/pacientes/alterar-senha", async (req, res) => {
    const { email, senhaAtual, novaSenha } = req.body;

    if (!email || !senhaAtual || !novaSenha) {
        return res.status(400).json({
            success: false,
            message: "Email, senha atual e nova senha são obrigatórios",
        });
    }

    let connection;
    try {
        // Obter conexão do pool
        connection = await pool.getConnection();

        // Verificar se o paciente existe e a senha atual está correta
        const [pacientes] = await connection.execute("SELECT id, senha FROM pacientes WHERE email = ?", [email]);

        if (pacientes.length === 0) {
            return res.status(404).json({
                success: false,
                message: "Paciente não encontrado", // ← Corrigido: era "Cuidador"
            });
        }

        const paciente = pacientes[0];

        // Verificar senha atual - CORREÇÃO AQUI ✅
        if (senhaAtual !== paciente.senha) {
            // ← Era "pacientes.senha" (array)
            return res.status(401).json({
                success: false,
                message: "Senha atual incorreta",
            });
        }

        // Atualizar a senha
        await connection.execute("UPDATE pacientes SET senha = ? WHERE email = ?", [novaSenha, email]);

        res.json({
            success: true,
            message: "Senha alterada com sucesso",
        });
    } catch (error) {
        console.error("Erro ao alterar senha do paciente:", error);
        res.status(500).json({
            success: false,
            message: "Erro interno do servidor",
        });
    } finally {
        // Liberar a conexão de volta para o pool
        if (connection) connection.release();
    }
});

// Endpoint para alterar senha do cuidador
app.put("/api/familiares/alterar-senha", async (req, res) => {
    const { email, senhaAtual, novaSenha } = req.body;

    if (!email || !senhaAtual || !novaSenha) {
        return res.status(400).json({
            success: false,
            message: "Email, senha atual e nova senha são obrigatórios",
        });
    }

    let connection;
    try {
        // Obter conexão do pool
        connection = await pool.getConnection();

        // Verificar se o familiar existe e a senha atual está correta
        const [familiares] = await connection.execute("SELECT id, senha FROM familiares WHERE email = ?", [email]);

        if (familiares.length === 0) {
            return res.status(404).json({
                success: false,
                message: "Familiar não encontrado",
            });
        }

        const familiar = familiares[0];

        // Verificar senha atual
        if (senhaAtual !== familiar.senha) {
            return res.status(401).json({
                success: false,
                message: "Senha atual incorreta",
            });
        }

        // Atualizar a senha
        await connection.execute("UPDATE familiares SET senha = ? WHERE email = ?", [novaSenha, email]);

        res.json({
            success: true,
            message: "Senha do familiar alterada com sucesso",
        });
    } catch (error) {
        console.error("Erro ao alterar senha do familiar:", error);
        res.status(500).json({
            success: false,
            message: "Erro interno do servidor",
        });
    } finally {
        // Liberar a conexão de volta para o pool
        if (connection) connection.release();
    }
});

// 2. Endpoint para atualizar perfil do cuidador - VERSÃO CORRIGIDA
app.put("/api/cuidador/atualizar-perfil", async (req, res) => {
    const { nome, numero, data_nascimento, endereco, info_fisicas } = req.body;

    if (!nome) {
        return res.status(400).json({
            success: false,
            message: "Nome é obrigatório",
        });
    }

    let connection;
    try {
        connection = await pool.getConnection();

        // Aqui você normalmente pegaria o ID do cuidador logado
        const cuidadorId = 1;

        // Converter data do formato DD/MM/YYYY para YYYY-MM-DD - CORREÇÃO AQUI
        let dataNascimentoMySQL = null;
        if (data_nascimento && data_nascimento.includes("/")) {
            try {
                const partes = data_nascimento.split("/");
                if (partes.length === 3) {
                    const dia = partes[0].padStart(2, "0");
                    const mes = partes[1].padStart(2, "0");
                    const ano = partes[2];

                    // Validar se são números
                    if (!isNaN(dia) && !isNaN(mes) && !isNaN(ano)) {
                        dataNascimentoMySQL = `${ano}-${mes}-${dia}`;

                        // Validar se a data é válida
                        const dataTeste = new Date(dataNascimentoMySQL);
                        if (isNaN(dataTeste.getTime())) {
                            console.warn("Data inválida recebida:", data_nascimento);
                            dataNascimentoMySQL = null;
                        }
                    }
                }
            } catch (error) {
                console.error("Erro ao converter data:", error);
                dataNascimentoMySQL = null;
            }
        }

        console.log("Dados recebidos para atualização:", {
            nome,
            numero,
            data_nascimento,
            dataNascimentoMySQL,
            endereco,
        });

        await connection.execute(
            `UPDATE cuidador 
       SET nome = ?, telefone = ?, data_nascimento = ?, endereco = ?
       WHERE id = ?`,
            [nome, numero, dataNascimentoMySQL, endereco, cuidadorId]
        );

        res.json({
            success: true,
            message: "Perfil atualizado com sucesso",
        });
    } catch (error) {
        console.error("Erro ao atualizar perfil:", error);
        res.status(500).json({
            success: false,
            message: "Erro interno do servidor: " + error.message,
        });
    } finally {
        if (connection) connection.release();
    }
});

app.put("/api/familiar/atualizar-perfil", async (req, res) => {
    const { nome, telefone, data_nascimento, endereco, email } = req.body;
    const id = 1; // ID do familiar

    if (!nome) {
        return res.status(400).json({
            success: false,
            message: "Nome é obrigatório",
        });
    }

    let connection;
    try {
        connection = await pool.getConnection();

        // Converter data do formato DD/MM/YYYY para YYYY-MM-DD
        let dataNascimentoMySQL = null;
        if (data_nascimento && data_nascimento.includes("/")) {
            try {
                const partes = data_nascimento.split("/");
                if (partes.length === 3) {
                    const dia = partes[0].padStart(2, "0");
                    const mes = partes[1].padStart(2, "0");
                    const ano = partes[2];

                    if (!isNaN(dia) && !isNaN(mes) && !isNaN(ano)) {
                        dataNascimentoMySQL = `${ano}-${mes}-${dia}`;

                        const dataTeste = new Date(dataNascimentoMySQL);
                        if (isNaN(dataTeste.getTime())) {
                            console.warn("Data inválida recebida:", data_nascimento);
                            dataNascimentoMySQL = null;
                        }
                    }
                }
            } catch (error) {
                console.error("Erro ao converter data:", error);
                dataNascimentoMySQL = null;
            }
        }

        console.log("📝 Dados para atualização:", {
            nome,
            telefone,
            data_nascimento,
            data_convertida: dataNascimentoMySQL,
            endereco,
            email,
        });

        const query = `
            UPDATE familiares 
            SET nome = ?, telefone = ?, data_nascimento = ?, endereco = ?, email = ?
            WHERE id = ?
        `;

        await connection.execute(query, [
            nome,
            telefone || null,
            dataNascimentoMySQL,
            endereco || null,
            email || null,
            id,
        ]);

        res.json({
            success: true,
            message: "Perfil do familiar atualizado com sucesso",
        });
    } catch (error) {
        console.error("Erro ao atualizar perfil do familiar:", error);
        res.status(500).json({
            success: false,
            message: "Erro interno do servidor: " + error.message,
        });
    } finally {
        if (connection) connection.release();
    }
});

app.put("/api/paciente/atualizar-perfil", async (req, res) => {
    const { nome, tipo_sanguineo, idade, peso, comorbidade } = req.body;
    const id = 1; // ID do paciente

    if (!nome) {
        return res.status(400).json({
            success: false,
            message: "Nome é obrigatório",
        });
    }

    let connection;
    try {
        connection = await pool.getConnection();

        console.log("📝 Dados para atualização do paciente:", {
            nome,
            tipo_sanguineo,
            idade,
            peso,
            comorbidade,
        });

        const query = `
            UPDATE pacientes 
            SET nome = ?, tipo_sanguineo = ?, idade = ?, peso = ?, comorbidade = ?
            WHERE id = ?
        `;

        await connection.execute(query, [
            nome,
            tipo_sanguineo || null,
            idade || null,
            peso || null,
            comorbidade || null,
            id,
        ]);

        res.json({
            success: true,
            message: "Perfil do paciente atualizado com sucesso",
        });
    } catch (error) {
        console.error("Erro ao atualizar perfil do paciente:", error);
        res.status(500).json({
            success: false,
            message: "Erro interno do servidor: " + error.message,
        });
    } finally {
        if (connection) connection.release();
    }
});

app.post("/api/registrosdiarios/novo", async (req, res) => {
    // Extrai os dados enviados pelo Flutter
    const { paciente_id, atividades_realizadas, outras_atividades, observacoes_gerais } = req.body;

    // Validação básica dos dados obrigatórios
    if (!paciente_id || typeof paciente_id !== "number") {
        return res.status(400).json({
            success: false,
            message: "ID do paciente é obrigatório e deve ser um número.",
        });
    }

    // Assumimos que a tabela é 'registros_diarios'
    const query = `
        INSERT INTO registros_diarios (
            paciente_id, 
            atividades_realizadas, 
            outras_atividades, 
            observacoes_gerais, 
            data_registro
        )
        VALUES (?, ?, ?, ?, NOW())
    `;

    const values = [paciente_id, atividades_realizadas, outras_atividades, observacoes_gerais];

    try {
        // Executa a query de inserção no banco de dados
        const [result] = await pool.execute(query, values);

        res.status(201).json({
            success: true,
            message: "Registro diário salvo com sucesso.",
            registro_id: result.insertId, // Retorna o ID do novo registro
        });
    } catch (error) {
        console.error("Erro ao salvar o registro diário:", error);
        res.status(500).json({
            success: false,
            message: "Erro interno do servidor ao salvar o registro.",
            error: error.message,
        });
    }
});

app.post("/api/registrosdiarios/sentimentos", async (req, res) => {
    const { paciente_id, estado_geral, observacoes_sentimentos } = req.body;

    if (!paciente_id || !estado_geral) {
        return res.status(400).json({
            success: false,
            message: "ID do paciente e Estado Geral são obrigatórios.",
        });
    }

    // Você precisará de uma tabela para armazenar esses sentimentos,
    // ou talvez atualizar o registro diário criado na etapa anterior.
    // Para simplificar, vamos criar uma tabela separada: 'sentimentos_diarios'.

    const query = `
        INSERT INTO registros_diarios (
            paciente_id, 
            estado_geral, 
            observacoes_sentimentos, 
            data_registro
        )
        VALUES (?, ?, ?, NOW())
    `;

    const values = [paciente_id, estado_geral, observacoes_sentimentos];

    try {
        const [result] = await pool.execute(query, values);

        res.status(201).json({
            success: true,
            message: "Sentimentos salvos com sucesso.",
            registro_id: result.insertId,
        });
    } catch (error) {
        console.error("Erro ao salvar os sentimentos:", error);
        res.status(500).json({
            success: false,
            message: "Erro interno do servidor ao salvar os sentimentos.",
            error: error.message,
        });
    }
});

app.post("/api/registrosdiarios/sinais-clinicos", async (req, res) => {
    const { paciente_id, temperatura, glicemia, pressao_arterial, outras_observacoes } = req.body;

    console.log("Dados recebidos:", req.body); // DEBUG

    if (!paciente_id) {
        return res.status(400).json({
            success: false,
            message: "ID do paciente é obrigatório.",
        });
    }

    try {
        // ... resto do código permanece igual
        // Verificar se já existe um registro diário para este paciente hoje
        const checkQuery = `
            SELECT id FROM registros_diarios 
            WHERE paciente_id = ? AND DATE(data_registro) = CURDATE()
        `;

        const [existingRecords] = await pool.execute(checkQuery, [paciente_id]);

        if (existingRecords.length > 0) {
            // Atualizar registro existente
            const updateQuery = `
                UPDATE registros_diarios 
                SET temperatura = ?, 
                    glicemia = ?, 
                    pressao_arterial = ?, 
                    outras_observacoes = ?
                WHERE paciente_id = ? AND DATE(data_registro) = CURDATE()
            `;

            const updateValues = [
                temperatura || null,
                glicemia || null,
                pressao_arterial || null,
                outras_observacoes || null,
                paciente_id,
            ];

            const [updateResult] = await pool.execute(updateQuery, updateValues);

            res.status(200).json({
                success: true,
                message: "Sinais clínicos atualizados com sucesso.",
                registro_id: existingRecords[0].id,
            });
        } else {
            // Criar novo registro
            const insertQuery = `
                INSERT INTO registros_diarios (
                    paciente_id, 
                    temperatura, 
                    glicemia, 
                    pressao_arterial, 
                    outras_observacoes,
                    data_registro
                )
                VALUES (?, ?, ?, ?, ?, NOW())
            `;

            const insertValues = [
                paciente_id,
                temperatura || null,
                glicemia || null,
                pressao_arterial || null,
                outras_observacoes || null,
            ];

            const [insertResult] = await pool.execute(insertQuery, insertValues);

            res.status(201).json({
                success: true,
                message: "Sinais clínicos salvos com sucesso.",
                registro_id: insertResult.insertId,
            });
        }
    } catch (error) {
        console.error("Erro ao salvar os sinais clínicos:", error);
        res.status(500).json({
            success: false,
            message: "Erro interno do servidor ao salvar os sinais clínicos.",
            error: error.message,
        });
    }
});

app.get("/api/registrosdiarios", async (req, res) => {
    try {
        const query = `
            SELECT 
                rd.*,
                p.nome as paciente_nome,
                p.idade as paciente_idade,
                p.tipo_sanguineo,
                p.comorbidade,
                DATE_FORMAT(rd.data_registro, '%d/%m/%Y %H:%i') as data_formatada
            FROM registros_diarios rd
            INNER JOIN pacientes p ON rd.paciente_id = p.id
            ORDER BY rd.data_registro DESC
        `;

        const [registros] = await pool.execute(query);

        if (registros.length === 0) {
            return res.json({
                success: true,
                data: [],
                message: "Nenhum registro encontrado",
            });
        }

        res.json({
            success: true,
            data: registros,
            total: registros.length,
        });
    } catch (error) {
        console.error("Erro ao buscar registros:", error);
        res.status(500).json({
            success: false,
            message: "Erro interno do servidor",
            error: error.message,
        });
    }
});

const PORT = process.env.PORT || 8000;
app.listen(PORT, () => {
    console.log(`Servidor rodando na porta ${PORT}`);
});

app.post("/api/delete-account", async (req, res) => {
    try {
        const { userId, confirmacao } = req.body;

        console.log("Tentativa de deletar conta:", { userId, confirmacao });

        // Validações
        if (!userId) {
            return res.status(400).json({
                success: false,
                message: "ID do usuário é obrigatório",
            });
        }

        if (!confirmacao || confirmacao !== "CONFIRMAR_DELECAO") {
            return res.status(400).json({
                success: false,
                message: "Confirmação de deleção é necessária",
            });
        }

        // Verificar se o cuidador existe
        const [user] = await pool.execute("SELECT id, email FROM cuidador WHERE id = ?", [userId]);

        if (user.length === 0) {
            return res.status(404).json({
                success: false,
                message: "Usuário não encontrado",
            });
        }

        console.log("Cuidador encontrado:", user[0].email);

        // Iniciar transação
        const connection = await pool.getConnection();
        await connection.beginTransaction();

        try {
            // 1. Deletar registros_diarios dos pacientes do cuidador
            await connection.execute(
                `DELETE rd FROM registros_diarios rd 
                 INNER JOIN pacientes p ON rd.paciente_id = p.id 
                 WHERE p.cuidador_id = ?`,
                [userId]
            );

            // 2. Deletar tarefas dos pacientes do cuidador
            await connection.execute("DELETE FROM tarefas WHERE cuidador_id = ?", [userId]);

            // 3. Deletar consultas dos pacientes do cuidador
            await connection.execute("DELETE FROM consultas WHERE cuidador_id = ?", [userId]);

            // 4. Deletar agendamentos_medicamentos dos pacientes do cuidador
            await connection.execute("DELETE FROM agendamentos_medicamentos WHERE cuidador_id = ?", [userId]);

            // 5. Deletar pacientes do cuidador
            await connection.execute("DELETE FROM pacientes WHERE cuidador_id = ?", [userId]);

            // 6. Deletar o cuidador
            const [result] = await connection.execute("DELETE FROM cuidador WHERE id = ?", [userId]);

            // Confirmar transação
            await connection.commit();
            connection.release();

            console.log("Conta deletada com sucesso. Linhas afetadas:", result.affectedRows);

            res.json({
                success: true,
                message: "Conta e todos os dados associados foram deletados com sucesso",
                affectedRows: result.affectedRows,
            });
        } catch (transactionError) {
            // Reverter transação em caso de erro
            await connection.rollback();
            connection.release();
            console.error("Erro na transação:", transactionError);
            throw transactionError;
        }
    } catch (error) {
        console.error("Erro ao deletar conta:", error);
        res.status(500).json({
            success: false,
            message: "Erro interno do servidor ao deletar conta",
            error: error.message,
        });
    }
});

app.post("/api/familiar/delete-account", async (req, res) => {
    try {
        console.log("=== INICIANDO DELETE DO FAMILIAR ===");

        const { userId, confirmacao } = req.body;
        const familiarId = userId || 1; // Usa o ID do body ou fixo 1 para teste

        console.log("Dados recebidos:", { userId, confirmacao, familiarId });

        // Validação básica
        if (!confirmacao || confirmacao !== "CONFIRMAR_DELECAO") {
            return res.status(400).json({
                success: false,
                message: "Confirmação de deleção é necessária",
            });
        }

        // Verificar se o familiar existe
        const [user] = await pool.execute("SELECT id, email FROM familiares WHERE id = ?", [familiarId]);

        if (user.length === 0) {
            console.log("Familiar não encontrado");
            return res.status(404).json({
                success: false,
                message: "Familiar não encontrado",
            });
        }

        console.log("Familiar encontrado:", user[0].email);

        // Deletar o familiar
        const [result] = await pool.execute("DELETE FROM familiares WHERE id = ?", [familiarId]);

        console.log("Delete executado. Linhas afetadas:", result.affectedRows);

        res.json({
            success: true,
            message: "Conta do familiar deletada com sucesso",
            affectedRows: result.affectedRows,
            familiarDeletado: user[0].email,
        });
    } catch (error) {
        console.error("Erro detalhado:", error);
        res.status(500).json({
            success: false,
            message: "Erro interno do servidor",
            error: error.message,
            stack: error.stack,
        });
    }
});

app.post("/api/paciente/delete-account", async (req, res) => {
    try {
        console.log("=== INICIANDO DELETE DO PACIENTE ===");

        const { userId, confirmacao } = req.body;
        const pacienteId = userId || 1; // Usa o ID do body ou fixo 1 para teste

        console.log("Dados recebidos:", { userId, confirmacao, pacienteId });

        // Validação básica
        if (!confirmacao || confirmacao !== "CONFIRMAR_DELECAO") {
            return res.status(400).json({
                success: false,
                message: "Confirmação de deleção é necessária",
            });
        }

        // Verificar se o paciente existe
        const [user] = await pool.execute("SELECT id, email, nome FROM pacientes WHERE id = ?", [pacienteId]);

        if (user.length === 0) {
            console.log("Paciente não encontrado");
            return res.status(404).json({
                success: false,
                message: "Paciente não encontrado",
            });
        }

        console.log("Paciente encontrado:", user[0].nome, user[0].email);

        // Iniciar transação para deletar todas as dependências
        const connection = await pool.getConnection();
        await connection.beginTransaction();

        try {
            // 1. Deletar registros_diarios do paciente
            await connection.execute("DELETE FROM registros_diarios WHERE paciente_id = ?", [pacienteId]);
            console.log("Registros diários deletados");

            // 2. Deletar tarefas do paciente
            await connection.execute("DELETE FROM tarefas WHERE paciente_id = ?", [pacienteId]);
            console.log("Tarefas deletadas");

            // 3. Deletar consultas do paciente
            await connection.execute("DELETE FROM consultas WHERE paciente_id = ?", [pacienteId]);
            console.log("Consultas deletadas");

            // 4. Deletar agendamentos_medicamentos do paciente
            await connection.execute("DELETE FROM agendamentos_medicamentos WHERE paciente_id = ?", [pacienteId]);
            console.log("Agendamentos de medicamentos deletados");

            // 5. Deletar o paciente
            const [result] = await connection.execute("DELETE FROM pacientes WHERE id = ?", [pacienteId]);

            // Confirmar transação
            await connection.commit();
            connection.release();

            console.log("Paciente deletado com sucesso. Linhas afetadas:", result.affectedRows);

            res.json({
                success: true,
                message: "Conta do paciente e todos os dados associados foram deletados com sucesso",
                affectedRows: result.affectedRows,
                pacienteDeletado: {
                    id: user[0].id,
                    nome: user[0].nome,
                    email: user[0].email,
                },
            });
        } catch (transactionError) {
            // Reverter transação em caso de erro
            await connection.rollback();
            connection.release();
            console.error("Erro na transação do paciente:", transactionError);
            throw transactionError;
        }
    } catch (error) {
        console.error("Erro ao deletar conta do paciente:", error);
        res.status(500).json({
            success: false,
            message: "Erro interno do servidor ao deletar conta do paciente",
            error: error.message,
            stack: error.stack,
        });
    }
});

// --- 5. INICIA O SERVIDOR ---
app.listen(port, () => {
    console.log(`Servidor Node.js rodando em http://localhost:${port}`);
    console.log(`Endpoint POST acesso: http:// localhost:${port}/api/paciente/cadastrocompleto`);
    console.log(`Endpoint POST famiiliar: http:// localhost:${port}/api/familiar/login`);
    console.log(`Endpoint POST login: http:// localhost:${port}/api/familiar/cadastro`);
    console.log(`Endpoint POST login: http:// localhost:${port}/api/cuidador/cadastro`);
    console.log(`Endpoint POST login: http:// localhost:${port}/api/cuidador/profissional`);
    console.log(`Endpoint POST login: http:// localhost:${port}/api/cuidador/login`);
    console.log(`Endpoint POST login: http:// localhost:${port}/api/cuidador/perfil`);
    console.log(`Endpoint POST login: http:// localhost:${port}/api/paciente/perfil`);
    console.log(`Endpoint POST login: http:// localhost:${port}/api/cuidador/MedicamentoPaciente`);
    console.log(`Endpoint POST login: http:// localhost:${port}/api/cuidador/PacienteConsulta`);
    console.log(`Endpoint POST login: http:// localhost:${port}/api/cuidador/SelecionarPacienteMedicamento`);
    console.log(`Endpoint POST login: http:// localhost:${port}/api/medicamentos`);
    console.log(`Endpoint POST login: http:// localhost:${port}/api/cuidador/SelecionarPacienteConsulta`);
    console.log(`Endpoint POST login: http:// localhost:${port}/api/cuidador/PacienteTarefa`);
    console.log(`Endpoint POST login: http:// localhost:${port}/api/cuidador/SelecionarPacienteTarefa`);
    console.log(`Endpoint POST login: http:// localhost:${port}/api/cuidador/PacienteComConsulta`);
    console.log(`Endpoint POST login: http:// localhost:${port}/api/cuidador/PacienteComMedicamentos`);
    console.log(`Endpoint POST login: http:// localhost:${port}/api/cuidador/PacienteComTarefas`);
    console.log(`Endpoint POST login: http:// localhost:${port}/api/paciente/login`);
    console.log(`Endpoint POST login: http:// localhost:${port}/api/cuidador/ExibirPacientes`);
    console.log(`Endpoint POST login: http:// localhost:${port}/api/cuidador/PacienteComAgendaCompleta`);
    console.log(`Endpoint POST login: http:// localhost:${port}/api/cuidador/familiar/meus-dados`);
    console.log(`Endpoint POST famiiliar: http:// localhost:${port}/api/familiar/perfil`);
    console.log(`Endpoint POST famiiliar: http:// localhost:${port}/api/cuidador/alterar-senha`);
    console.log(`Endpoint POST famiiliar: http:// localhost:${port}/api/pacientes/alterar-senha`);
    console.log(`Endpoint POST famiiliar: http:// localhost:${port}/api/familiares/alterar-senha`);
    console.log(`Endpoint POST famiiliar: http:// localhost:${port}/api/cuidador/atualizar-perfil`);
    console.log(`Endpoint POST famiiliar: http:// localhost:${port}/api/familiar/atualizar-perfil`);
    console.log(`Endpoint POST famiiliar: http:// localhost:${port}/api/paciente/atualizar-perfil`);
    console.log(`Endpoint POST famiiliar: http:// localhost:${port}/api/registrosdiarios/novo`);
    console.log(`Endpoint POST famiiliar: http:// localhost:${port}/api/registrosdiarios/sentimentos`);
    console.log(`Endpoint POST famiiliar: http:// localhost:${port}/api/registrosdiarios/sinais-clinicos`);
    console.log(`Endpoint POST famiiliar: http:// localhost:${port}/api/registrosdiarios`);
    console.log(`Endpoint POST famiiliar: http:// localhost:${port}/api/tarefa/:id/status`);
    console.log(`Endpoint POST famiiliar: http:// localhost:${port}/api/delete-account`);
    console.log(`Endpoint POST famiiliar: http:// localhost:${port}/api/familiar/delete-account`);
    console.log(`Endpoint POST famiiliar: http:// localhost:${port}/api/paciente/delete-account`);
});
