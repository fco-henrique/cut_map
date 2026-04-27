export function getVerificationEmailTemplate(
  name: string,
  code: string,
): string {
  return `
<!DOCTYPE html>
<html lang="pt-BR">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
  <link href="https://fonts.googleapis.com/css2?family=Bebas+Neue&family=DM+Sans:wght@400;500&display=swap" rel="stylesheet"/>
</head>
<body style="margin:0;padding:0;background:#1a1a1a;font-family:'DM Sans',sans-serif;">
  <table width="100%" cellpadding="0" cellspacing="0">
    <tr><td align="center" style="padding:32px 16px;">
      <table width="520" cellpadding="0" cellspacing="0" style="background:#111;border-radius:4px;border:1px solid #2a2a2a;overflow:hidden;">

        <tr><td style="height:4px;background:#F5C800;"></td></tr>

        <tr><td align="center" style="padding:36px 40px 28px;border-bottom:3px solid #F5C800;">
          <!-- ícone de tesoura SVG aqui, ou omitir em clientes de email -->
          <span style="font-family:'Bebas Neue',sans-serif;font-size:38px;letter-spacing:6px;color:#F5C800;display:block;">CUT MAP</span>
          <span style="font-size:11px;letter-spacing:4px;color:#666;text-transform:uppercase;">Your barber, your way</span>
        </td></tr>

        <tr><td style="padding:40px 40px 32px;">
          <p style="color:#999;font-size:13px;letter-spacing:1px;text-transform:uppercase;margin:0 0 12px;">Olá, ${name}</p>
          <h1 style="color:#fff;font-family:'Bebas Neue',sans-serif;font-size:28px;letter-spacing:3px;margin:0 0 16px;">Confirme seu e-mail</h1>
          <p style="color:#888;font-size:14px;line-height:1.7;margin:0 0 32px;">
            Quase lá! Para ativar sua conta no Cut Map e começar a agendar com os melhores barbeiros da sua região, use o código abaixo.
          </p>

          <table width="100%" cellpadding="0" cellspacing="0" style="background:#1a1a1a;border:1px solid #2a2a2a;border-left:4px solid #F5C800;border-radius:4px;margin:0 0 32px;">
            <tr><td align="center" style="padding:24px;">
              <span style="color:#666;font-size:11px;letter-spacing:3px;text-transform:uppercase;display:block;margin-bottom:12px;">Seu código de verificação</span>
              <span style="font-family:'Bebas Neue',sans-serif;font-size:48px;letter-spacing:12px;color:#F5C800;display:block;">${code}</span>
              <span style="color:#555;font-size:12px;margin-top:10px;display:block;">Expira em 15 minutos</span>
            </td></tr>
          </table>

          <p style="color:#555;font-size:12px;line-height:1.6;margin:0;">
            Se você não criou uma conta no <strong style="color:#777;">Cut Map</strong>, ignore este e-mail com segurança.
          </p>
        </td></tr>

        <tr><td align="center" style="background:#0a0a0a;border-top:1px solid #222;padding:24px 40px;">
          <span style="font-family:'Bebas Neue',sans-serif;font-size:16px;letter-spacing:4px;color:#333;display:block;margin-bottom:8px;">CUT MAP</span>
          <p style="color:#444;font-size:11px;line-height:1.6;margin:0;">
            © 2025 Cut Map. Todos os direitos reservados.<br/>
            <a href="#" style="color:#666;">Política de Privacidade</a> · <a href="#" style="color:#666;">Descadastrar</a>
          </p>
        </td></tr>

      </table>
    </td></tr>
  </table>
</body>
</html>
  `;
}
