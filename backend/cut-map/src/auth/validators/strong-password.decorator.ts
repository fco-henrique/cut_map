import { applyDecorators } from '@nestjs/common';
import { IsString, Matches } from 'class-validator';

export const STRONG_PASSWORD_MESSAGE =
  'A senha deve ter no mínimo 8 caracteres, com letra maiúscula, letra minúscula, número e caractere especial.';

const STRONG_PASSWORD_REGEX =
  /^(?=.{8,}$)(?=.*\p{Ll})(?=.*\p{Lu})(?=.*\d)(?=.*[^\p{L}\p{N}\s])/u;

/**
 * Política única de senha (cadastro, recuperação e alteração):
 * mínimo de 8 caracteres com maiúscula, minúscula, número e caractere especial.
 */
export function IsStrongPassword() {
  return applyDecorators(
    IsString(),
    Matches(STRONG_PASSWORD_REGEX, { message: STRONG_PASSWORD_MESSAGE }),
  );
}
