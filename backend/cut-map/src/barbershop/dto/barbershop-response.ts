import type { BarbershopMember } from '../entities/barbershop-member.entity';
import type { Barbershop } from '../entities/barbershop.entity';

export function toMemberResponse({
  id,
  role,
  user,
  barbershop,
}: BarbershopMember) {
  return {
    id,
    role,
    user: user && { id: user.id, name: user.name },
    barbershop: barbershop && { id: barbershop.id },
  };
}

export function toBarbershopResponse(barbershop: Barbershop) {
  const {
    id,
    name,
    address,
    phone,
    description,
    openingHours,
    averageRating,
    totalReviews,
    members,
  } = barbershop;
  return {
    id,
    name,
    address,
    phone,
    description,
    openingHours,
    averageRating,
    totalReviews,
    members: members?.map(toMemberResponse),
  };
}
