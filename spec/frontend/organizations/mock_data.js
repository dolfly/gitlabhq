export const pageInfoMultiplePages = {
  endCursor: 'eyJpZCI6IjEwNTMifQ',
  hasNextPage: true,
  hasPreviousPage: true,
  startCursor: 'eyJpZCI6IjEwNzIifQ',
  __typename: 'PageInfo',
};

export const pageInfoOnePage = {
  endCursor: 'eyJpZCI6IjEwNTMifQ',
  hasNextPage: false,
  hasPreviousPage: false,
  startCursor: 'eyJpZCI6IjEwNzIifQ',
  __typename: 'PageInfo',
};

export const pageInfoEmpty = {
  endCursor: null,
  hasNextPage: false,
  hasPreviousPage: false,
  startCursor: null,
  __typename: 'PageInfo',
};

export const defaultOrganization = {
  id: 1,
  name: 'Default',
  web_url: '/o/default/-/overview',
  avatar_url: null,
};

export const mockOrganizationsResponse = {
  data: {
    organizations: {
      nodes: [
        {
          id: 'gid://gitlab/Organizations::Organization/1',
          name: 'Test Org',
          avatarUrl: null,
          groups: {
            nodes: [
              {
                id: 'gid://gitlab/Group/1',
                fullName: 'Test Group',
                groupMembersCount: 5,
                projectsCount: 10,
                descendantGroupsCount: 2,
                visibility: 'private',
              },
            ],
          },
        },
      ],
    },
  },
};
