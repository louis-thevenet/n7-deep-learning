def clean(filename):
    '''
    Updates the file by removing duplicates
    '''
    with open(filename, 'r') as file:
        lines = file.readlines()
    unique_lines = set(lines)
    with open(filename, 'w') as file:
        file.writelines(unique_lines)
    