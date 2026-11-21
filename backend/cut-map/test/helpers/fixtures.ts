export const syntheticUsers = {
  ownerAlpha: {
    name: 'Proprietário Alpha',
    email: 'owner.alpha@synthetic.cutmap.test',
    password: 'SenhaForte123!',
  },
  ownerBeta: {
    name: 'Proprietário Beta',
    email: 'owner.beta@synthetic.cutmap.test',
    password: 'SenhaForte456!',
  },
  candidateGamma: {
    name: 'Barbeiro Gamma',
    email: 'barber.gamma@synthetic.cutmap.test',
    password: 'SenhaForte789!',
  },
  rot04User: {
    name: 'Usuário Rotação 04',
    email: 'rot04.user@synthetic.cutmap.test',
    password: 'SenhaForteRot04!',
  },
};

export const syntheticBarbershops = {
  storeAlpha: {
    name: 'Barbearia Alpha Prime',
    phone: '1130000001',
    description: 'Barbearia sintética de teste',
    openingHours: [{ dayOfWeek: 1, opensAt: '09:00', closesAt: '18:00' }],
    address: {
      cep: '01310100',
      rua: 'Avenida Paulista',
      numero: '1000',
      bairro: 'Bela Vista',
      cidade: 'São Paulo',
      estado: 'SP',
      pais: 'Brasil',
      latitude: -23.5615,
      longitude: -46.656,
    },
  },
  storeBeta: {
    name: 'Barbearia Beta Concept',
    phone: '1130000002',
    description: 'Barbearia sintética de teste',
    openingHours: [{ dayOfWeek: 1, opensAt: '09:00', closesAt: '18:00' }],
    address: {
      cep: '04538133',
      rua: 'Avenida Brigadeiro Faria Lima',
      numero: '2000',
      bairro: 'Itaim Bibi',
      cidade: 'São Paulo',
      estado: 'SP',
      pais: 'Brasil',
      latitude: -23.5855,
      longitude: -46.6805,
    },
  },
};
