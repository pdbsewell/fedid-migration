/*******************************************************************************
   * @author       Ryan Wilson
   * @date         10.Jan.2017         
   * @description  Custom Iterator class use to parse CSV content.
   * @revision     
   *******************************************************************************/
global with sharing class CSVIterator implements Iterator<String>, Iterable<String>
{
   private String m_CSVData;
   private String m_introValue;
   
   public CSVIterator(String fileData, String introValue)
   {
      m_CSVData = fileData;
      m_introValue = introValue; 
   }

   global Boolean hasNext()
   {
      System.debug('****TEST CSV DATA '+m_CSVData);
      System.debug('****TEST HAS NEXT '+m_CSVData.length());
      return m_CSVData.length() > 1 ? true : false;
   }

   global String next()
   {
      String row = '';
      try{
          row = m_CSVData.subString(0, m_CSVData.indexOf(m_introValue));
          m_CSVData = m_CSVData.subString(m_CSVData.indexOf(m_introValue) + m_introValue.length(),m_CSVData.length());
      }
      catch(exception ex){
          row = m_CSVData;
          m_CSVData = m_CSVData.subString(m_CSVData.indexOf(m_introValue) + m_introValue.length(),m_CSVData.length());
      }
      return row;
   }
   
   global Iterator<String> Iterator()
   {
      return this;   
   }
}